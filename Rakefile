
begin
  require 'rubygems'
  require 'hanna/rdoctask'
rescue
  require 'rake/rdoctask'
end

desc 'Generate RDoc documentation for the will_paginate plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_files.include('README.rdoc', 'LICENSE')
  rdoc.rdoc_files.include('lib/shadow_puppet/*.rb')

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

