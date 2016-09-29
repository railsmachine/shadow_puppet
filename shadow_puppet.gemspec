# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'shadow_puppet/version'

Gem::Specification.new do |spec|
  spec.name          = "shadow_puppet"
  spec.version       = ShadowPuppet::VERSION
  spec.authors       = ["Jesse Newland", "Josh Nichols", "Eric Lindvall",
                        "Lee Jones", "Will Farrington", "dreamcat4",
                        "Patrick Schless", "Ches Martin", "Rob Lingle",
                        "Scott Fleckenstein", "Bryan Traywick"]
  spec.email         = ["bryan@railsmachine.com"]
  spec.description   = %q{A Ruby Puppet DSL}
  spec.summary       = %q{A Ruby Puppet DSL}
  spec.homepage      = "https://github.com/railsmachine/shadow_puppet/"
  spec.license       = "LGPL"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "puppet", "~> 4.4.1"
  spec.add_runtime_dependency "activesupport", ">= 2.2.0", "< 5.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.8.0"
  spec.add_development_dependency "rspec-core", "~> 2.8.0"
  spec.add_development_dependency "rubocop"
end
