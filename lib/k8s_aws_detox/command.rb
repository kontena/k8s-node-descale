require 'aws-sdk-ec2'
require 'base64'
require 'clamp'
require 'k8s-client'
require 'tempfile'
require 'time'
require 'tty-which'

require_relative 'temp_kubeconfig'
require_relative 'kubectl'
require_relative 'scheduler'
require_relative 'version'

module K8sAwsDetox
  class Command < Clamp::Command
    banner "Drains and terminates Kubernetes nodes running in Amazon EC2 after they reach the specified best-before date."

    option '--aws-access-key', 'ACCESS_KEY', 'AWS access key ID', environment_variable: 'AWS_ACCESS_KEY_ID' do |aws_key|
      ENV['AWS_ACCESS_KEY_ID'] = aws_key
    end

    option '--aws-secret-key', 'SECRET_KEY', 'AWS secret access key', environment_variable: 'AWS_SECRET_ACCESS_KEY' do |aws_secret|
      ENV['AWS_SECRET_ACCESS_KEY'] = aws_secret
    end

    option '--kubectl', 'PATH', 'specify path to kubectl (default: $PATH)', attribute_name: :kubectl_path do |kubectl|
      File.executable?(kubectl) || signal_usage_error("kubectl at #{kubectl} not found or unusable")
      kubectl
    end

    option '--kube-config', 'PATH', 'Kubernetes config path', environment_variable: 'KUBECONFIG'
    option '--kube-server', 'ADDRESS', 'Kubernetes API server address', environment_variable: 'KUBE_SERVER'
    option '--kube-ca', 'DATA', 'Kubernetes certificate authority data', environment_variable: 'KUBE_CA'
    option '--kube-token', 'TOKEN', 'Kubernetes access token', environment_variable: 'KUBE_TOKEN'

    option '--max-age', 'DURATION', 'maximum age of server before draining and terminating', default: '3d', environment_variable: 'MAX_AGE'
    option '--max-nodes', 'COUNT', 'drain maximum of COUNT nodes per cycle', default: 1, environment_variable: 'MAX_NODES_COUNT' do |count|
      Integer(count)
    end

    option '--check-period', 'SCHEDULE', 'run periodically, example: --check-period 1h', environment_variable: 'CHECK_PERIOD', attribute_name: :scheduler do |period|
      unless period.match?(/^\d+[hmsdy]$/)
        signal_usage_error "invalid format for --check-period. use <number><unit>, example: 30s, 1h, 3d"
      end
      Scheduler.new(period)
    end

    option '--dry-run', :flag, "perform a dry-run, doesn't drain or terminate any instances.", default: false, environment_variable: 'DRY_RUN'
    option ['-v', '--version'], :flag, "Display k8s-aws-detox version" do
      puts "k8s-aws-detox version #{K8sAwsDetox::VERSION}"
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

        terminated_count = 0

        nodes.each do |node|
          name = node.metadata&.name
          Log.debug { "Node name %p" % name }
          next if name.nil?

          provider_id = node.spec&.providerID
          Log.debug { "Node provider_id: %p" % provider_id }
          if provider_id.nil? || !provider_id.start_with?('aws:///')
            Log.debug { "Node %s does not have a providerID" % name }
            next
          end

          region = node.metadata&.labels&.send(:'failure-domain.beta.kubernetes.io/region')
          Log.debug { "Node region: %p" % region }
          if region.nil?
            Log.debug { "Node %s does not have the metadata.labels[failure-domain.beta.kubernetes.io/region] region name" % name }
            next
          end

          node_id = provider_id[%r{aws:///.+?\/(.*)}, 1]
          Log.debug { "Node id: %p" % node_id }

          age_secs = (Time.now - Time.xmlschema(node.metadata.creationTimestamp)).to_i
          Log.debug { "Node %s (%s) age: %d seconds" % [name, provider_id, age_secs] }

          if age_secs > max_age_seconds
            Log.warn "!!! Node #{name} max-age expired, terminating !!!"

            ec2_instance = ec2_resource(region).instance(node_id)
            Log.debug { "Node ec2 instance: %p" % ec2_instance }

            if ec2_instance.nil? || !ec2_instance.exists?
              Log.warn "ec2 instance %s (%s) not found" % [name, node_id]
              next
            end

            case ec2_instance.state.code
            when 48  # terminated
              Log.info "Node %s (%s) has already been terminated" % [name, node_id]
              next
            else
              if dry_run?
                Log.info "[dry-run] Would drain node %s (%s)" % [name, node_id]
              else
                Log.debug { "Draining node %s (%s) .." % [name, node_id] }
                drain_node(name)
                Log.debug { "Done draining node %s (%s)" % [name, node_id] }
              end

              begin
                Log.debug { "Terminating node %s (%s)" % [name, node_id] }
                ec2_instance.terminate(dry_run: dry_run?)
              rescue Aws::EC2::Errors::DryRunOperation
                Log.info "[dry-run] Node termination dry-run check passed"
              rescue => ex
                if dry_run?
                  Log.error "[dry-run] Node %s (%s) termination dry-run check reports an error: %s : %s" % [name, node_id, ex, ex.message]
                else
                  Log.error "Failed to terminate node %s (%s): %s : %s" % [name, node_id, ex, ex.message]
                  next
                end
              end

              terminated_count += 1
              if terminated_count >= max_nodes
                Log.info "Reached termination --max-nodes count, breaking cycle."
                break
              end

            end
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
      @kubectl ||= Kubectl.new(kubectl_path, kube_config_file)
    end

    def drain_node(name)
      kubectl.drain(name)
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

    def kube_client
      @kube_client ||= K8s::Client.config(K8s::Config.load_file(kube_config_file))
    end

    def kube_config_file
      return @kube_config_file if @kube_config_file

      if kube_config
        Log.debug { "using kubeconfig from --kube-config=%s" % kube_config }
        @kube_config_file = kube_config
      elsif kube_token || kube_server || kube_ca
        Log.debug { "using kubeconfig built from --kube-*" }
        unless kube_token && kube_server && kube_ca
          signal_usage_error "--kube-token --kube-server and --kube-ca are required to be used together"
        end
        @kube_config_file = TempKubeconfig.new(kube_token, kube_server, kube_ca).path
      elsif File.exist?(File.join(Dir.home, '.kube', 'config'))
        Log.debug { "using kubeconfig from ~/.kube/config" }
        @kube_config_file = File.join(Dir.home, '.kube', 'config')
      elsif File.readable?('/etc/kubernetes/admin.conf')
        Log.debug { "using kubeconfig from /etc/kubernetes/admin.conf" }
        @kube_config_file = '/etc/kubernetes/admin.conf'
      else
        temp_config = TempKubeconfig.in_cluster_config
        signal_usage_error 'missing configuration for kubernetes credentials' if temp_config.nil?
        Log.debug { "using kubeconfig from in_cluster_config" }
        @kube_config_file = temp_config.path
      end
    end

    def ec2_resource(region)
      # uses ENV variables, default config file or instance profile (when running on ec2) for credentials
      # the option parser sets the env variables when options are given
      Aws::EC2::Resource.new(region: region)
    end
  end
end
