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

