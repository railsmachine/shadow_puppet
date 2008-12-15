Gem::Specification.new do |s|
  s.name = %q{moonshine}
  s.version = "0.0.1"
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jesse Newland"]
  s.date = %q{2008-11-14}
  s.description = %q{moonshine}
  s.email = ["jesse@railsmachine.com"]
  s.default_executable = %q{moonshine}
  s.executables = ["moonshine"]
  s.files = [
    "bin/moonshine",
    "lib/facts/moonshine.rb",
    "lib/moonshine.rb",
    "lib/moonshine/cli.rb",
    "lib/moonshine/manifest.rb",
    "lib/moonshine/manifest/rails.rb",
    "lib/moonshine/application.rb"
  ]
  s.has_rdoc = false
  s.homepage = %q{http://railsmachine.com}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{Moonshine deployment agent}

  s.add_dependency(%q<puppet>, [">= 0.24.6"])
  s.add_dependency(%q<facter>, [">= 1.5.2"])
  s.add_dependency(%q<highline>, [">= 1.5.0"])
end
