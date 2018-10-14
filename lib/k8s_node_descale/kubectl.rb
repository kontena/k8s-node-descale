require 'retriable'

module K8sNodeDescale
  class Kubectl
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def drain(node_name, dry_run: false)
      Retriable.retriable do
        Log.debug { "Running kubectl drain" }
        cmd = [path, "drain", '--timeout=5m', '--ignore-daemonsets', '--delete-local-data']
        cmd << '--dry-run' if dry_run
        cmd << node_name
        unless system(*cmd)
          Log.error "kubectl drain failed"
          raise "kubectl drain failed"
        end
      end
    end
  end
end
