require 'rubygems'
require 'ruby-debug'
require 'bundler'

Bundler.module_eval do
  class << self
    def root
      Pathname.new(__FILE__).dirname.dirname
    end

    def definition
      builder = Bundler::Dsl.new
      builder.instance_eval do
        gem 'puppet', '= 0.24.8'
        gem 'facter', '>= 1.5.4'
        gem 'highline', '>= 1.5.0'
        gem 'builder', '>= 2.1.2'
        gem 'activesupport', "= #{ENV['ACTIVESUPPORT_VERSION'] || '2.3.8'}"
        group :test do
          gem 'rspec', '~> 1.3.0'
        end
      end
      builder.to_definition
    end
  end
end

Bundler.runtime.setup(:default, :test)

require 'spec'
require 'spec/autorun'

$LOAD_PATH.unshift Pathname.new(__FILE__).dirname.dirname + 'lib'
  
require 'shadow_puppet'
require 'shadow_puppet/test'
Dir.glob(File.join(File.dirname(__FILE__), 'fixtures', '*.rb')).each do |manifest|
  require manifest
end
