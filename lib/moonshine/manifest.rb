require 'puppet'
require 'puppet/dsl'
require 'erb'
gem "activesupport"
require 'active_support'

module Moonshine
  class Manifest

    attr_reader :application, :run
    attr_accessor :objects
    class_inheritable_accessor :recipes
    self.recipes = []

    def initialize(application = nil)
      unless Process.uid == 0
          Puppet[:confdir] = File.expand_path("~/.puppet")
          Puppet[:vardir] = File.expand_path("~/.puppet/var")
      end
      Puppet[:user] = Process.uid
      Puppet[:group] = Process.gid
      Puppet::Util::Log.newdestination(:console)
      Puppet::Util::Log.level = :info
      @application = application
      @run = false
      #typed collection of objects
      @objects = Hash.new do |hash, key|
        hash[key] = {}
      end
      @resources = []
    end

    def self.recipe(*args)
      return nil if args.nil? || args == []
      args.each do |a|
        recipes << a.to_sym
      end
    end

    def reference(type, title)
      Puppet::Parser::Resource::Reference.new(:type => type.to_s, :title => title.to_s, :scope => scope)
    end

    def application
      Moonshine::Application.current
    end

    def config
      facts["moonshine"].each do |app_name, config|
        return config if app_name.to_sym == application.to_sym
      end
      return nil
    end

    #Create an instance method for every type that either creates or references
    #a resource
    Puppet::Type.loadall
    Puppet::Type.eachtype do |type|
      define_method(type.name) do |*args|
        if args && args.flatten.size == 1
          reference(type.name, args.first)
        else
          newresource(type, args.first, args.last)
        end
      end
    end

    def scope
      unless defined?(@scope)
        # Set the code to something innocuous; we just need the
        # scopes, not the interpreter.  Hackish, but true.
        Puppet[:code] = " "
        @interp = Puppet::Parser::Interpreter.new
        require 'puppet/node'
        @node = Puppet::Node.new(Facter.value(:hostname))
        if env = Puppet[:environment] and env == ""
          env = nil
        end
        @node.parameters = Facter.to_hash
        @compile = Puppet::Parser::Compiler.new(@node, @interp.send(:parser, env))
        @scope = @compile.topscope
      end
      @scope
    end

    def newresource(type, name, params = {})
      unless obj = @objects[type][name]
        obj = Puppet::Parser::Resource.new(
          :title => name,
          :type => self.class.to_s,
          :source => self,
          :scope => scope
        )
        @objects[type][name] = obj
        @resources << obj
      end

      params.each do |param_name, param_value|
        param = Puppet::Parser::Resource::Param.new(
          :name => param_name,
          :value => param_value,
          :source => self
        )
        obj.send(:set_parameter, param)
      end

      obj
    end

    def facts
      Facter.flush
      Facter.to_hash
    end

    def application_config
      facts["moonshine"].each do |app_name, config|
        return config if app_name.to_sym == application.to_sym
      end
      return nil
    end

    def run?
      @run
    end

    def run
      return false if self.run?
      evaluate
      apply
    rescue Exception => e
      raise e
    else
      true
    ensure
      @run = true
    end

    def evaluate
      self.class.recipes.each do |r|
        self.send(r.to_sym)
      end
    end

    def apply
      bucket = export()
      catalog = bucket.to_catalog
      catalog.apply
    end

    def export
      transportable_objects = @resources.dup.reject { |a| a.nil? }.flatten.collect do |obj|
        obj.to_trans
      end
      bucket = Puppet::TransBucket.new(transportable_objects)
      bucket.name = "moonshine:#{object_id}"
      bucket.type = "class"

      return bucket
    end

    #needed
    def name
      self.class.to_s
    end

  end
end

Dir.glob(File.join(File.dirname(__FILE__), '..', 'facts', '*.rb')).each do |fact|
  require fact
end
# Dir.glob(File.join(File.dirname(__FILE__), 'modules', '*.rb')).each do |mod|
#   require mod
# end
# Dir.glob(File.join(File.dirname(__FILE__), 'manifest', '*.rb')).each do |manifest|
#   require manifest
# end