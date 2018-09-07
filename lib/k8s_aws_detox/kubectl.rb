require 'retriable'

module K8sAwsDetox
  class Kubectl
    attr_reader :path, :kubeconfig_file

    def initialize(path, kubeconfig_file)
      @path = path
      @kubeconfig_file = kubeconfig_file
    end

    def drain(node_name, dry_run: false)
      Retriable.retriable do
        Log.debug { "Running kubectl drain" }
        cmd = [path, "drain", '--kubeconfig=%s' % kubeconfig_file, '--timeout=5m', '--ignore-daemonsets']
        cmd << '--dry-run' if dry_run
        cmd << node-name
        unless system(*cmd)
          Log.error "kubectl drain failed"
          raise "kubectl drain failed"
        end
      end
    end
  end
end
