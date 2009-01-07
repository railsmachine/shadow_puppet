require 'rubygems'
require File.join(File.dirname(__FILE__), '..', 'lib', 'moonshine.rb')
require File.join(File.dirname(__FILE__), '..', 'lib', 'moonshine', 'manifest.rb')
Dir.glob(File.join(File.dirname(__FILE__), 'fixtures', '*.rb')).each do |manifest|
  require manifest
end