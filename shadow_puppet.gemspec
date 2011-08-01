# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{shadow_puppet}
  s.version = "0.5.0.rc7"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jesse Newland", "Josh Nichols", "Eric Lindvall", "Lee Jones", "Will Farrington", "dreamcat4", "Patrick Schless", "Ches Martin", "Rob Lingle", "Scott Fleckenstein"]
  s.date = %q{2011-08-01}
  s.description = %q{A Ruby Puppet DSL}
  s.email = %q{jesse@railsmachine.com}
  s.executables = ["shadow_puppet"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    ".gitmodules",
    "Isolate",
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "bin/shadow_puppet",
    "examples/foo.rb",
    "lib/shadow_puppet.rb",
    "lib/shadow_puppet/core_ext.rb",
    "lib/shadow_puppet/manifest.rb",
    "lib/shadow_puppet/test.rb",
    "shadow_puppet.gemspec",
    "spec/cli_spec.rb",
    "spec/fixtures/cli_spec_manifest.rb",
    "spec/fixtures/manifests.rb",
    "spec/manifest_spec.rb",
    "spec/spec_helper.rb",
    "spec/test_spec.rb",
    "spec/type_spec.rb"
  ]
  s.homepage = %q{http://railsmachine.github.com/shadow_puppet}
  s.rdoc_options = ["--inline-source", "--webcvs=http://github.com/railsmachine/shadow_puppet/tree/master/"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{moonshine}
  s.rubygems_version = %q{1.7.2}
  s.summary = %q{A Ruby Puppet DSL}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<puppet>, ["= 2.7.1"])
      s.add_runtime_dependency(%q<facter>, ["= 1.6.0"])
      s.add_runtime_dependency(%q<highline>, [">= 1.5.0"])
      s.add_runtime_dependency(%q<builder>, [">= 2.1.2"])
      s.add_runtime_dependency(%q<activesupport>, [">= 2.0.0"])
      s.add_runtime_dependency(%q<i18n>, ["~> 0.6.0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.6.0"])
      s.add_development_dependency(%q<rspec-core>, ["~> 2.6.0"])
      s.add_development_dependency(%q<isolate>, ["~> 3.1.0"])
      s.add_development_dependency(%q<isolate-scenarios>, ["~> 0.1.1"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.2"])
    else
      s.add_dependency(%q<puppet>, ["= 2.7.1"])
      s.add_dependency(%q<facter>, ["= 1.6.0"])
      s.add_dependency(%q<highline>, [">= 1.5.0"])
      s.add_dependency(%q<builder>, [">= 2.1.2"])
      s.add_dependency(%q<activesupport>, [">= 2.0.0"])
      s.add_dependency(%q<i18n>, ["~> 0.6.0"])
      s.add_dependency(%q<rspec>, ["~> 2.6.0"])
      s.add_dependency(%q<rspec-core>, ["~> 2.6.0"])
      s.add_dependency(%q<isolate>, ["~> 3.1.0"])
      s.add_dependency(%q<isolate-scenarios>, ["~> 0.1.1"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.2"])
    end
  else
    s.add_dependency(%q<puppet>, ["= 2.7.1"])
    s.add_dependency(%q<facter>, ["= 1.6.0"])
    s.add_dependency(%q<highline>, [">= 1.5.0"])
    s.add_dependency(%q<builder>, [">= 2.1.2"])
    s.add_dependency(%q<activesupport>, [">= 2.0.0"])
    s.add_dependency(%q<i18n>, ["~> 0.6.0"])
    s.add_dependency(%q<rspec>, ["~> 2.6.0"])
    s.add_dependency(%q<rspec-core>, ["~> 2.6.0"])
    s.add_dependency(%q<isolate>, ["~> 3.1.0"])
    s.add_dependency(%q<isolate-scenarios>, ["~> 0.1.1"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.2"])
  end
end

