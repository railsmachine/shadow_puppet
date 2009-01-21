Gem::Specification.new do |s|
  s.name = %q{shadow_facter}
  s.version = "0.0.1"
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jesse Newland"]
  s.date = %q{2008-11-14}
  s.description = %q{shadow_facter}
  s.email = ["jesse@railsmachine.com"]
  s.default_executable = %q{shadow_facter}
  s.executables = ["shadow_facter"]
  s.files = [
    "Readme",
    "lib/shadow_facter.rb",
    "lib/shadow_facter/manifest.rb",
  ]
  s.has_rdoc = false
  s.homepage = %q{http://railsmachine.com}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{A Ruby Puppet DSL}

  s.add_dependency(%q<puppet>, [">= 0.24.6"])
  s.add_dependency(%q<facter>, [">= 1.5.2"])
  s.add_dependency(%q<highline>, [">= 1.5.0"])
  s.add_dependency(%q<builder>, [">= 2.1.2"])
  s.add_dependency(%q<activesupport>, [">= 2.2.2"])
end
