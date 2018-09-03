
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "k8s_aws_detox/version"

Gem::Specification.new do |spec|
  spec.name          = "k8s_aws_detox"
  spec.version       = K8sAwsDetox::VERSION
  spec.authors       = ["Kontena, Inc"]
  spec.email         = ["info@kontena.io"]

  spec.summary       = %q{AWS EC2 Kubernetes node clean-up}
  spec.description   = %q{Drains and terminates AWS EC2 Kubernetes nodes when they exceed their best-before date}
  spec.homepage      = "https://github.com/kontena/k8s-aws-detox"

  spec.files         = Dir["bin/*", "lib/**/*", "LICENSE", "README.md" "k8s_aws_detox.gemspec"]
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "clamp", "~> 1.3"
  spec.add_runtime_dependency "aws-sdk-ec2", "~> 1.43"
  spec.add_runtime_dependency "k8s-client", "~> 0.3"
  spec.add_runtime_dependency "rufus-scheduler", "~> 3.5"
  spec.add_runtime_dependency "tty-which", "~> 0.3"
  spec.add_runtime_dependency "retriable", "~> 3.1"
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rspec", "~> 3.0"
end
