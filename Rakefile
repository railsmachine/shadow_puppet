require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "shadow_puppet"
  gem.summary = %Q{A Ruby Puppet DSL}
  gem.description = %Q{A Ruby Puppet DSL}
  gem.email = "jesse@railsmachine.com"
  gem.homepage = "http://railsmachine.github.com/shadow_puppet"
  gem.rubyforge_project = "moonshine"
  gem.authors = ["Jesse Newland", "Josh Nichols", "Eric Lindvall", "Lee Jones", "Will Farrington", "dreamcat4", "Patrick Schless", "Ches Martin", "Rob Lingle", "Scott Fleckenstein"]

  gem.version = "0.5.0b1"

  gem.add_dependency('puppet', ["= 2.6.8"])
  gem.add_dependency('facter', [">= 1.5.8"])
  gem.add_dependency('highline', [">= 1.5.0"])
  gem.add_dependency('builder', [">= 2.1.2"])
  gem.add_dependency('activesupport', [">= 2.0.0"])

  gem.rdoc_options << '--inline-source' << '--webcvs=http://github.com/railsmachine/shadow_puppet/tree/master/'

  gem.add_development_dependency "rspec", ">= 0"
  gem.add_development_dependency "isolate-scenarios", ">= 0"

  # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
end
Jeweler::GemcutterTasks.new


begin
  require 'rubygems'
  require 'hanna/rdoctask'
rescue LoadError
  require 'rake/rdoctask'
end
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_files.include('lib/shadow_puppet/*.rb')
  rdoc.rdoc_files.include('bin/shadow_puppet')
  rdoc.rdoc_files.include('README.rdoc')

  rdoc.main = "README.rdoc" # page to start on
  rdoc.title = "ShadowPuppet documentation"
  
  rdoc.rdoc_dir = 'doc' # rdoc output folder
  rdoc.options << '--webcvs=http://github.com/railsmachine/shadow_puppet/tree/master/'
end

task :default => :spec
task :spec do
  system("spec --options spec/spec.opts spec/*_spec.rb") || raise
end

task :build => :cleanup do
  system "gem build *.gemspec"
end

task :install => :build do
  system "sudo gem install *.gem"
end

task :uninstall do
  system "sudo gem uninstall *.gem"
end

task :cleanup do
  system "rm *.gem"
end

task :pull do
  system "git pull origin master"
  system "git pull github master"
end

task :_push do
  system "git push origin master"
  system "git push github master"
end

task :push => [:redoc, :pull, :spec, :_push]

task :redoc do
  #clean
  system "git checkout gh-pages && git pull origin gh-pages && git pull github gh-pages"
  system "rm -rf doc"
  system "git checkout master"
  system "rm -rf doc"

  #doc
  Rake::Task['rdoc'].invoke

  #switch branch
  system "git checkout gh-pages"

  #move it all to the root
  system "cp -r doc/* . && rm -rf doc"

  #commit and push
  system "git commit -am 'regenerate rdocs' && git push origin gh-pages && git push github gh-pages"
  system "git checkout master"
end
