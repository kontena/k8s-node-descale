
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "k8s_node_descale/version"

Gem::Specification.new do |spec|
  spec.name          = "k8s_asg_detox"
  spec.version       = K8sNodeDescale::VERSION
  spec.authors       = ["Kontena, Inc"]
  spec.email         = ["info@kontena.io"]
  spec.license       = "Apache-2.0"

  spec.summary       = %q{Kubernetes autoscaling node clean-up}
  spec.description   = %q{Drains Kubernetes nodes when they exceed their best-before date}
  spec.homepage      = "https://github.com/kontena/k8s-node-descale"

  spec.files         = Dir["bin/*", "lib/**/*", "LICENSE", "README.md" "k8s_asg_detox.gemspec"]
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "clamp", "~> 1.3"
  spec.add_runtime_dependency "k8s-client", "~> 0.3"
  spec.add_runtime_dependency "rufus-scheduler", "~> 3.5"
  spec.add_runtime_dependency "tty-which", "~> 0.3"
  spec.add_runtime_dependency "retriable", "~> 3.1"
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rspec", "~> 3.0"
end
