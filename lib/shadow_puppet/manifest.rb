require 'puppet'
require 'erb'
gem "activesupport"
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/core_ext/array'
require 'active_support/inflector'

module ShadowFacter
  class Manifest

    attr_reader :application, :puppet_resources
    attr_accessor :objects, :bucket
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

      #need to combine the two below things, no need to keep both

      #typed collection of objects
      @objects = Hash.new do |hash, key|
        hash[key] = {}
      end
      #flat array of objects
      @puppet_resources = []
    end

    #class level method that declares that a method creating resources will be
    #called when an instance of this class is run
    def self.recipe(*args)
      return nil if args.nil? || args == []
      options = args.extract_options!
      args.each do |a|
        recipes << [a.to_sym, options]
      end
    end

    #helper to easily create a reference to an existing resource
    def reference(type, title)
      Puppet::Parser::Resource::Reference.new(:type => type.to_s, :title => title.to_s, :scope => scope)
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

    #convenince method for accessing facts
    def facts
      Facter.flush
      Facter.to_hash
    end

    #has this manifest instance been run yet?
    def run?
      @run
    end

    #returns true if <tt>self.respond_to?</tt> all methods named by calls recipe
    def runnable?
      self.class.recipes.each do |meth,args|
        return false unless self.respond_to?(meth)
      end
      true
    end

    #evaulate and apply this manifest
    def run
      return false if self.run?
      return false unless self.runnable?
      evaluate
      apply
    rescue Exception => e
      raise e
    else
      true
    ensure
      @run = true
    end

    private

    #evaluate the methods defined by the call to self.recipe
    def evaluate
      self.class.recipes.each do |meth, args|
        case arity = self.method(meth).arity
        when 1, -1
          self.send(meth, args)
        else
          self.send(meth)
        end
      end
    end

    #apply the evaluated manifest, that is, execute it
    def apply
      @bucket ||= export()
      catalog = @bucket.to_catalog
      catalog.apply
    end

    #export this manifest as a transportable bucket
    def export
      transportable_objects = @puppet_resources.dup.reject { |a| a.nil? }.flatten.collect do |obj|
        obj.to_trans
      end
      b = Puppet::TransBucket.new(transportable_objects)
      b.name = "shadow_puppet:#{object_id}"
      b.type = "class"

      return b
    end

    def scope #:nodoc:
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

    #creates a new resource
    def newresource(type, name, params = {})
      unless obj = @objects[type][name]
        obj = Puppet::Parser::Resource.new(
          :title => name,
          :type => type.name,
          :source => self,
          :scope => scope
        )
        @objects[type][name] = obj
        @puppet_resources << obj
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

  end
end

Dir.glob(File.join(File.dirname(__FILE__), '..', 'facts', '*.rb')).each do |fact|
  require fact
end