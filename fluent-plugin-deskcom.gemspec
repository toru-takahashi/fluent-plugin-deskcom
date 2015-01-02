# coding: utf-8
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-deskcom"
  spec.version       = "0.0.1"
  spec.authors       = ["Toru Takahashi"]
  spec.email         = ["torutakahashi.ayashi@gmail.com"]
  spec.summary       = %q{Input plugin to collect data from Deskcom.}
  spec.description   = %q{fluent Input plugin to collect data from Deskcom.}
  spec.homepage      = "https://github.com/toru-takahashi/fluent-plugin-deskcom"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_runtime_dependency "fluentd"
  spec.add_runtime_dependency "desk"
end
