require 'rubygems'
gem 'rspec'
require 'spec'
require File.join(File.dirname(__FILE__), '..', 'lib', 'shadow_facter.rb')
Dir.glob(File.join(File.dirname(__FILE__), 'fixtures', '*.rb')).each do |manifest|
  require manifest
end