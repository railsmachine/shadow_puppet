require 'bundler'
Bundler.require(:default, :development)

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))
$LOAD_PATH.unshift(File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib'))

require 'shadow_puppet/core_ext'
require 'shadow_puppet'
require 'shadow_puppet/test'

Dir.glob(File.join(File.expand_path(File.dirname(__FILE__)), 'fixtures', '*.rb')).each do |manifest|
  require manifest
end
