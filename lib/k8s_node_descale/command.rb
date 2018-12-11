require 'k8s_node_descale/version'

require 'base64'
require 'clamp'
require 'k8s-client'
require 'tempfile'
require 'time'
require 'tty-which'

require_relative 'kubectl'
require_relative 'scheduler'

module K8sNodeDescale
  class Command < Clamp::Command
    banner "Kubernetes Auto-scaling Group Descale - Drains after they reach their specified best-before date."

    option '--kubectl', 'PATH', 'specify path to kubectl (default: $PATH)', attribute_name: :kubectl_path do |kubectl|
      File.executable?(kubectl) || signal_usage_error("kubectl at #{kubectl} not found or unusable")
      kubectl
    end

    option '--kube-config', 'PATH', 'Kubernetes config path', environment_variable: 'KUBECONFIG'
    option '--max-age', 'DURATION', 'maximum age of server before draining', default: '3d', environment_variable: 'MAX_AGE'
    option '--max-nodes', 'COUNT', 'drain maximum of COUNT nodes per cycle', default: 1, environment_variable: 'MAX_NODES_COUNT' do |count|
      Integer(count)
    end

    option '--check-period', 'SCHEDULE', 'run periodically, example: --check-period 1h', environment_variable: 'CHECK_PERIOD', attribute_name: :scheduler do |period|
      unless period.match?(/^\d+[hmsdy]$/)
        signal_usage_error "invalid format for --check-period. use <number><unit>, example: 30s, 1h, 3d"
      end
      Scheduler.new(period)
    end

    option '--dry-run', :flag, "perform a dry-run, doesn't drain any instances.", default: false, environment_variable: 'DRY_RUN'
    option ['-v', '--version'], :flag, "Display k8s-node-descale version" do
      puts "k8s-node-descale version #{K8sNodeDescale::VERSION}"
      exit 0
    end

    execute do
      Log.debug { "Validating kube credentials" }
      begin
        kubectl
        kube_client.api('v1').resource('nodes').list
      rescue => ex
        signal_usage_error 'failed to connect to Kubernetes API, see --help for connection options (%s)' % ex.message
      end

      scheduler.run do
        Log.debug { "Requesting node information .." }

        nodes = kube_client.api('v1').resource('nodes').list
        nodes.delete_if { |node| node.spec&.taints&.map(&:key)&.include?('node-role.kubernetes.io/master') }

        Log.debug { "Kubernetes API lists %d nodes" % nodes.size }

        nodes.each do |node|
          name = node.metadata&.name
          Log.debug { "Node name %p" % name }
          next if name.nil?

          age_secs = (Time.now - Time.xmlschema(node.metadata.creationTimestamp)).to_i
          Log.debug { "Node %s age: %d seconds" % [name, age_secs] }

          if age_secs > max_age_seconds
            Log.warn "!!! Node #{name} max-age expired, terminating !!!"

            if dry_run?
              Log.info "[dry-run] Would drain node %s" % name
            else
              Log.debug { "Draining node %s .." % name }
            end
            drain_node(name)
            Log.debug { "Done draining node %s" % name }
          else
            Log.debug { "Node %s has not reached best-before" % name }
          end
        end

        Log.debug { "Round completed .." }
      end
    end

    def default_kubectl_path
      TTY::Which.which('kubectl') || signal_usage_error('kubectl not found in PATH, use --kubectl <path> to set location manually')
    end

    def kubectl
      @kubectl ||= Kubectl.new(kubectl_path)
    end

    def drain_node(name)
      kubectl.drain(name, dry_run: dry_run?)
    end

    def default_scheduler
      Scheduler.new
    end

    def max_age_seconds
      @max_age_seconds ||= to_sec(max_age)
    end

    def to_sec(duration_string)
      num = duration_string[0..-2].to_i
      case duration_string[-1]
      when 's' then num
      when 'm' then num * 60
      when 'h' then num * 60 * 60
      when 'd' then num * 60 * 60 * 24
      when 'w' then num * 60 * 60 * 24 * 7
      when 'M' then num * 60 * 60 * 24 * 30
      when 'Y' then num * 60 * 60 * 24 * 365
      else
        signal_usage_error 'invalid --max-age format'
      end
    end

    private

    # @return [K8s::Client]
    def kube_client
      return @kube_client if @kube_client

      if kube_config
        @kube_client = K8s::Client.config(K8s::Config.load_file(kube_config))
      else
        @kube_client = K8s::Client.in_cluster_config
      end

      @kube_client
    end
  end
end
