require 'rubygems'
require 'bundler'
Bundler.setup(:default, :development)
require 'appraisal'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "shadow_puppet"
  gem.summary = %Q{A Ruby Puppet DSL}
  gem.description = %Q{A Ruby Puppet DSL}
  gem.email = "will@railsmachine.com"
  gem.homepage = "http://railsmachine.github.com/shadow_puppet"
  gem.rubyforge_project = "moonshine"
  gem.authors = ["Jesse Newland", "Josh Nichols", "Eric Lindvall", "Lee Jones", "Will Farrington", "dreamcat4", "Patrick Schless", "Ches Martin", "Rob Lingle", "Scott Fleckenstein"]

  gem.version = "0.6.1"

  gem.rdoc_options << '--inline-source' << '--webcvs=http://github.com/railsmachine/shadow_puppet/tree/master/'

  # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
end
Jeweler::GemcutterTasks.new


require 'rdoc/task'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_files.include('lib/shadow_puppet/*.rb')
  rdoc.rdoc_files.include('bin/shadow_puppet')
  rdoc.rdoc_files.include('README.rdoc')

  rdoc.main = "README.rdoc" # page to start on
  rdoc.title = "ShadowPuppet documentation"
  
  rdoc.rdoc_dir = 'doc' # rdoc output folder
  rdoc.options << '--webcvs=http://github.com/railsmachine/shadow_puppet/tree/master/'
end

require 'rspec/core/rake_task'

desc 'Default: run specs.'
task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  # Put spec opts in a file named .rspec in root
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
