# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sessel/version'

Gem::Specification.new do |spec|
  spec.name          = "sessel"
  spec.version       = Sessel::VERSION
  spec.authors       = ["Rafal Nowosielski"]
  spec.email         = ["rafal@nowosielski.email"]

  spec.summary       = "The gem includes a tool to store SES configuration in a scriptable form"
  spec.description   = "When writing solutions in the cloud, it is often valuable to have all configuraiton in code. Sonce CloutFormation doesn't support SES, this gem provides a way to store this confiuration in a scriptable form"
  spec.homepage      = "https://nowosielski.website"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"

  spec.add_runtime_dependency "aws-sdk", "~> 2.6"
  spec.add_runtime_dependency "thor"
  spec.add_runtime_dependency "highline", "2.0.0.pre.develop.6"

end
