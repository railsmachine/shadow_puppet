module ShadowPuppet
  # A Manifest is an executable collection of Puppet Resources[http://reductivelabs.com/trac/puppet/wiki/TypeReference].
  #
  # ===Example
  #
  #   class ManifestExample < ShadowPuppet::Manifest
  #     recipe :sample
  #     recipe :lamp, :ruby               # queue calls to self.lamp and
  #                                       # self.ruby when executing
  #
  #     recipe :mysql, {                  # queue a call to self.mysql
  #       :root_password => 'OMGSEKRET'   # passing the provided hash
  #     }                                 # as an option
  #
  #     def sample
  #       exec :foo, :command => 'echo "foo" > /tmp/foo.txt'
  #
  #       package :foo, :ensure => :installed
  #
  #       file '/tmp/example.txt',
  #         :ensure   => :present,
  #         :contents => Facter.to_hash_inspect,
  #         :require  => package(:foo)
  #     end
  #
  #     def lamp
  #       #install a basic LAMP stack
  #     end
  #
  #     def ruby
  #       #install a ruby interpreter and tools
  #     end
  #
  #     def mysql(options)
  #        #install a mysql server and set the root password to options[:root_password]
  #     end
  #
  #   end
  #
  # To execute the above manifest, instantiate it and call execute on it:
  #
  #   m = ManifestExample.new
  #   m.execute
  #
  # As shown in the +sample+ method in ManifestExample above, instance
  # methods are created for each Puppet::Type available on your system. These
  # methods behave identally to the Puppet Resources methods. See here[http://reductivelabs.com/trac/puppet/wiki/TypeReference]
  # for documentation on these methods.
  #
  # To view a list of all defined methods on your system, run:
  #
  #    ruby -rubygems -e 'require "shadow_puppet";puts ShadowPuppet::Manifest.puppet_type_methods'
  #
  # The use of methods (+sample+, +lamp+, +ruby+, and +mysql+ above) as a
  # container for resources facilitates recipie re-use through the use of Ruby
  # Modules. For example:
  #
  #   module ApachePuppet
  #     # Required options:
  #     #   domain
  #     #   path
  #     def php_vhost(options)
  #       #...
  #     end
  #    end
  #
  #   class MyWebMainfest < ShadowPuppet::Manifest
  #     include ApachePuppet
  #     recipe :php_vhost, {
  #       :domain => 'foo.com',
  #       :path => '/var/www/apps/foo'
  #     }
  #   end
  class Manifest

    class_inheritable_accessor :recipes
    write_inheritable_attribute(:recipes, [])
    attr_reader :puppet_resources
    class_inheritable_accessor :__configatron__
    write_inheritable_attribute(:__configatron__, Configatron::Store.new)

    # Initialize a new instance of this manifest. This can take a
    # config hash, which is immediately passed on to the configure
    # method
    def initialize(config = {})
      if Process.uid == 0
        Puppet[:confdir] = File.expand_path("/etc/shadow_puppet")
        Puppet[:vardir] = File.expand_path("/var/shadow_puppet")
      else
        Puppet[:confdir] = File.expand_path("~/.shadow_puppet")
        Puppet[:vardir] = File.expand_path("~/.shadow_puppet/var")
      end
      Puppet[:user] = Process.uid
      Puppet[:group] = Process.gid
      Puppet::Util::Log.newdestination(:console)

      configure(config)
      @executed = false
      @puppet_resources = Hash.new do |hash, key|
        hash[key] = {}
      end
    end

    # Declares that the named method or methods will be called whenever
    # execute is called on an instance of this class. If the last argument is
    # a Hash, this hash is passed as an argument to all provided methods.
    # If no options hash is provided, each method is passed the contents of
    # <tt>configuration[method]</tt>.
    #
    # Subclasses of the Manifest class properly inherit the parent classes'
    # calls to recipe.
    def self.recipe(*methods)
      return nil if methods.nil? || methods == []
      options = methods.extract_options!
      methods.each do |meth|
        options = configatron.send(meth.to_sym) if options == {}
        options ||= {}
        recipes << [meth.to_sym, options]
      end
    end

    def self.configatron
      __configatron__
    end

    def configatron
      self.class.__configatron__
    end

    # A hash describing any configuration that has been
    # performed on the class. Modify this hash by calling configure:
    #
    #   class SampleManifest < ShadowPuppet::Manifest
    #     configure(:name => 'test')
    #   end
    #
    #   >> SampleManifest.configuration
    #   => {"name" => 'test'}
    #
    # Subclasses of the Manifest class properly inherit the parent classes'
    # configuration.
    def self.configuration
      configatron.to_hash
    end

    # Access to the configuration of the creating class.
    def configuration
      self.class.configuration
    end

    # Define configuration on this manifest. This is useful for storing things
    # such as hostnames, password, or usernames that may change between
    # different implementations of a shared manifest. Access this hash by
    # calling configuration:
    #
    #   class SampleManifest < ShadowPuppet::Manifest
    #     configure(:name => 'test')
    #   end
    #
    #   >> SampleManifest.configuration
    #   => {"name" => 'test'}
    #
    # Subsequent calls to configure perform a deep_merge of the
    # provided <tt>hash</tt> into the pre-existing configuration
    def self.configure(hash)
      __configatron__.configure_from_hash(hash)
    end

    # Define configuration on this manifest's creating class. This is useful
    # for storing things such as hostnames, password, or usernames that may
    # change between different implementations of a shared manifest.
    def configure(hash)
      self.class.configure(hash)
    end
    alias_method :configuration=, :configure

    #An array of all methods defined for creation of Puppet Resources
    def self.puppet_type_methods
      Puppet::Type.eachtype { |t| t.name }.keys.map { |n| n.to_s }.sort.inspect
    end

    def name
      @name ||= "#{self.class}##{self.object_id}"
    end

    #Create an instance method for every type that either creates or references
    #a resource
    def self.register_puppet_types
      Puppet::Type.loadall
      Puppet::Type.eachtype do |type|
        #undefine the method rdoc placeholders
        undef_method(type.name) rescue nil
        define_method(type.name) do |*args|
          if args && args.flatten.size == 1
            reference(type.name, args.first)
          else
            new_resource(type, args.first, args.last)
          end
        end
      end
    end
    register_puppet_types

    # Returns true if this Manifest <tt>respond_to?</tt> all methods named by
    # calls to recipe, and if this Manifest has not been executed before.
    def executable?
      self.class.recipes.each do |meth,args|
        return false unless respond_to?(meth)
      end
      return false if executed?
      true
    end

    # Execute this manifest, applying all resources defined. By default, this
    # will only execute a manifest that is executable?. The +force+ argument,
    # if true, removes this check.
    def execute(force=false)
      return false unless executable? || force
      evaluate_recipes
      apply
    rescue Exception => e
      raise e
    else
      true
    ensure
      @executed = true
    end

    protected

    #Has this manifest instance been executed?
    def executed?
      @executed
    end

    #An Array of all currently defined resources.
    def flat_resources
      a = []
      @puppet_resources.each_value do |by_type|
        by_type.each_value do |by_name|
          a << by_name
        end
      end
      a
    end

    #A Puppet::TransBucket of all defined resoureces.
    def export
      transportable_objects = flat_resources.dup.reject { |a| a.nil? }.flatten.collect do |obj|
        obj.to_trans
      end
      b = Puppet::TransBucket.new(transportable_objects)
      b.name = name
      b.type = "class"

      return b
    end

    private

    #Evaluate the methods calls queued in self.recipes
    def evaluate_recipes
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
      catalog.clear
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

    #Create a reference to another Puppet Resource.
    def reference(type, title)
      Puppet::Parser::Resource::Reference.new(:type => type.to_s, :title => title.to_s, :scope => scope)
    end

    #Creates a new Puppet Resource.
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

      case type.name
      when :exec
        param = Puppet::Parser::Resource::Param.new(
          :name => :path,
          :value => ENV["PATH"],
          :source => self
        )
        obj.send(:set_parameter, param)
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