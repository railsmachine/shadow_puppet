require 'puppet'
require 'erb'
gem "activesupport"
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/core_ext/array'
require 'active_support/inflector'
require 'active_support/core_ext/hash/indifferent_access'

module ShadowPuppet
  # A Manifest is an executable collection of Puppet Resources[http://reductivelabs.com/trac/puppet/wiki/TypeReference].
  #
  # == Example
  #
  #  class Foo < ShadowPuppet::Manifest
  #    recipe :foo
  #
  #    def foo
  #      exec :foo, :command => '/bin/echo "foo" > /tmp/foo.txt'
  #      package :foo, :ensure => :installed
  #      file '/tmp/example.txt', :ensure => :present, :contents => Facter.to_hash_inspect
  #    end
  #  end
  #
  # As you can see in the above example, resources are created inside instance
  # methods defined on the class.
  class Manifest

    class_inheritable_accessor :recipes
    self.recipes = []
    attr_reader :puppet_resources

    # Initialize a new instance of this manifest. This can take a hash of
    # options that are avaliable later via the options method.
    def initialize(options = {})
      unless Process.uid == 0
          Puppet[:confdir] = File.expand_path("~/.puppet")
          Puppet[:vardir] = File.expand_path("~/.puppet/var")
      end
      Puppet[:user] = Process.uid
      Puppet[:group] = Process.gid
      Puppet::Util::Log.newdestination(:console)
      Puppet::Util::Log.level = :info

      @options = HashWithIndifferentAccess.new(options)
      @executed = false
      @puppet_resources = Hash.new do |hash, key|
        hash[key] = {}
      end
    end

    #class level method that declares that a method creating resources will be
    #called when an instance of this class is executed
    def self.recipe(*args)
      return nil if args.nil? || args == []
      options = args.extract_options!
      args.each do |a|
        recipes << [a.to_sym, options]
      end
    end

    # A HashWithIndifferentAccess[http://api.rubyonrails.com/classes/HashWithIndifferentAccess.html]
    # containing the options passed into the initialize method. Useful to pass
    # things not already in Facter.
    def options
      @options
    end

    #Create an instance method for every type that either creates or references
    #a resource
    Puppet::Type.loadall
    Puppet::Type.eachtype do |type|
      define_method(type.name) do |*args|
        if args && args.flatten.size == 1
          reference(type.name, args.first)
        else
          new_resource(type, args.first, args.last)
        end
      end
    end

    # Returns true if this Manifest <tt>respond_to?</tt> all methods named by
    # calls to recipe, and if this manifest has not been executed before.
    def executable?
      self.class.recipes.each do |meth,args|
        return false unless respond_to?(meth)
      end
      return false if executed?
      true
    end

    # Execute this manifest, applying all resources defined. By default, this
    # will only execute a manifest that is executable?. The ++force++ argument,
    # if true, removes this check
    def execute(force=false)
      return false unless executable? || force
      evaluate
      apply
    rescue Exception => e
      raise e
    else
      true
    ensure
      @executed = true
    end

    protected

    #Has this manifest instance been executed yet?
    def executed?
      @executed
    end

    #all resources currently defined, as an Array
    def flat_resources
      a = []
      @puppet_resources.each_value do |by_type|
        by_type.each_value do |by_name|
          a << by_name
        end
      end
      a
    end

    #Convert the contained Puppet Resources into a TransBucket
    def export
      transportable_objects = flat_resources.dup.reject { |a| a.nil? }.flatten.collect do |obj|
        obj.to_trans
      end
      b = Puppet::TransBucket.new(transportable_objects)
      b.name = "shadow_puppet:#{object_id}"
      b.type = "class"

      return b
    end

    private

    #Evaluate the methods calls queued in self.recipes
    def evaluate
      self.class.recipes.each do |meth, args|
        case arity = method(meth).arity
        when 1, -1
          send(meth, args)
        else
          send(meth)
        end
      end
    end

    # Create a catalog of all contained Puppet Resources and apply that
    # catalog to the currently running system
    def apply(bucket = nil)
      bucket ||= export()
      catalog = bucket.to_catalog
      catalog.apply
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

    #Create a reference to another Puppet Resource
    def reference(type, title)
      Puppet::Parser::Resource::Reference.new(:type => type.to_s, :title => title.to_s, :scope => scope)
    end

    #Creates a new Puppet Resource
    def new_resource(type, name, params = {})
      unless obj = @puppet_resources[type][name]
        obj = Puppet::Parser::Resource.new(
          :title => name,
          :type => type.name,
          :source => self,
          :scope => scope
        )
        @puppet_resources[type][name] = obj
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