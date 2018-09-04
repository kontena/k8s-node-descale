require 'retriable'

module K8sAwsDetox
  class Kubectl
    attr_reader :path, :kubeconfig_file

    def initialize(path, kubeconfig_file)
      @path = path
      @kubeconfig_file = kubeconfig_file
    end

    def drain(node_name)
      Retriable.retriable do
        Log.debug { "Running kubectl drain" }
        unless system(path, "drain", '--kubeconfig=%s' % kubeconfig_file, '--timeout=5m', '--ignore-daemonsets', node_name)
          Log.error "kubectl drain failed"
          raise "kubectl drain failed"
        end
      end
    end
  end
end
