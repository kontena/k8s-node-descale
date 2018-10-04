require 'logger'
require_relative 'k8s_node_descale/version'
require_relative 'k8s_node_descale/command'

module K8sNodeDescale
  Log = Logger.new($stdout).tap { |log| log.level = ENV["DEBUG"].to_s.empty? ? Logger::INFO : Logger::DEBUG }
end
