require 'tempfile'
require 'yaml'

module K8sNodeDescale
  class TempKubeconfig
    def self.in_cluster_config
      host = ENV['KUBERNETES_SERVICE_HOST']
      port = ENV['KUBERNETES_SERVICE_PORT_HTTPS']
      return nil unless host && port
      server = "https://#{host}:#{port}"

      ca_file = '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt'
      return nil unless File.readable?(ca_file)
      ca = File.read(ca_file)

      token_file = '/var/run/secrets/kubernetes.io/serviceaccount/token'
      return nil unless File.readable?(token_file)
      token = File.read(token_file)

      new(token, server, ca)
    end

    attr_reader :token, :server, :ca, :path

    def initialize(token = nil, server = nil, ca = nil)
      @token = token
      @server = server
      @ca = ca
      @path = temp_kubeconfig
    end

    def temp_kubeconfig
      tmpfle = Tempfile.new
      tmpfile << YAML.dump(
        clusters: [ { name: 'kubernetes', cluster: { server: server, certificate_authority_data: ca } } ],
        users: [ { name: 'k8snodedescale', user: { token: token } } ],
        contexts: [ { name: 'k8snodedescale', context: { cluster: 'kubernetes', user: 'k8sawsdetox' } } ],
        preferences: {},
        current_context: 'k8snodedescale'
      )
      tmpfile.close
      tmpfile.path
    end
  end
end
