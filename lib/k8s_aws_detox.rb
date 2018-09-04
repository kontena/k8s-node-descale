require 'logger'
require_relative 'k8s_aws_detox/version'
require_relative 'k8s_aws_detox/command'

module K8sAwsDetox
  Log = Logger.new($stdout).tap { |log| log.level = ENV["DEBUG"].to_s.empty? ? Logger::INFO : Logger::DEBUG }
end
