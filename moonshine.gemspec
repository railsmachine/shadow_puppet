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
    "init.rb",
    "rails/init.rb",
    "Readme",
    "bin/moonshine",
    "lib/facts/moonshine.rb",
    "lib/moonshine.rb",
    "lib/moonshine/cli.rb",
    "lib/moonshine/manifest.rb",
    "lib/moonshine/manifest/rails.rb",
    "lib/moonshine/manifest/user.rb",
    "lib/moonshine/manifest/setup.rb",
    "lib/moonshine/manifest/update.rb",
    "lib/moonshine/modules/user.rb",
    "lib/moonshine/modules/gem.rb",
    "lib/moonshine/modules/package.rb",
    "lib/moonshine/modules/ruby.rb",
    "lib/moonshine/modules/service.rb",
    "lib/moonshine/application.rb",
    "lib/templates/vhost.conf.erb"
  ]
  s.has_rdoc = false
  s.homepage = %q{http://railsmachine.com}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{Moonshine deployment management}

  s.add_dependency(%q<puppet>, [">= 0.24.6"])
  s.add_dependency(%q<facter>, [">= 1.5.2"])
  s.add_dependency(%q<highline>, [">= 1.5.0"])
  s.add_dependency(%q<activesupport>, [">= 2.2.2"])
end
