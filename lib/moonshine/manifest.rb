require 'puppet'
require 'puppet/dsl'
require 'erb'
gem "activesupport"
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/inflector'

class Puppet::Util::Log
  @loglevel = 0
end

class Puppet::DSL::Aspect
  def reference(type, title)
    Puppet::Parser::Resource::Reference.new(:type => type.to_s, :title => title.to_s)
  end
end

module Moonshine
  class Manifest
    include Puppet::DSL

    attr_reader :application
    attr_reader :instance_roles
    class_inheritable_accessor :class_roles
    self.class_roles = []

    def initialize(application = nil)
      init
      @application = application
      @instance_roles = []
    end

    def self.role(name, options = {}, &block)
      self.class_roles << Aspect.new(name, options, &block)
    end

    def manifest
      self
    end

    def run
      acquire(*@@class_roles)
      acquire(*@instance_roles)
      apply
    end
    alias_method :apply_all, :run

    def role(name, options = {}, &block)
      @instance_roles << Aspect.new(name, options, &block)
    end

    def apply_roles(*names)
      acquire(*names)
      apply
    end

  end

end

Dir.glob(File.join(File.dirname(__FILE__), '..', 'facts', '*.rb')).each do |fact|
  require fact
end
Dir.glob(File.join(File.dirname(__FILE__), 'modules', '*.rb')).each do |mod|
  require mod
  Moonshine::Manifest.send(:extend, File.basename(mod, ".rb").classify.constantize)
end
Dir.glob(File.join(File.dirname(__FILE__), 'manifest', '*.rb')).each do |manifest|
  require manifest
end