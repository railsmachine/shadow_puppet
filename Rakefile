begin
  require 'rubygems'
  require 'hanna/rdoctask'
rescue
  require 'rake/rdoctask'
end

desc 'Generate RDoc documentation for the will_paginate plugin.'
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
  system "spec --options spec/spec.opts spec/*_spec.rb"
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
  system "cd doc && git pull origin gh-pages && git pull github gh-pages"
  system "mv doc tmpdoc"
  Rake::Task['rdoc'].invoke
  system "cp -r doc/* tmpdoc/"
  system "rm -rf doc"
  system "mv tmpdoc doc"
  system "cd doc && git commit -am 'regenerate rdocs' && git push origin gh-pages && git push github gh-pages"
  system "git commit doc -m 'update docs submodule'"
end