require 'rubygems'
require 'isolate/scenarios/now'
gem 'rspec'
require 'spec'
require File.join(File.dirname(__FILE__), '..', 'lib', 'shadow_puppet', 'core_ext.rb')
require File.join(File.dirname(__FILE__), '..', 'lib', 'shadow_puppet.rb')
require File.join(File.dirname(__FILE__), '..', 'lib', 'shadow_puppet', 'test.rb')
Dir.glob(File.join(File.dirname(__FILE__), 'fixtures', '*.rb')).each do |manifest|
  require manifest
end
