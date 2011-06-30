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
  #       # install a basic LAMP stack
  #     end
  #
  #     def ruby
  #       # install a ruby interpreter and tools
  #     end
  #
  #     def mysql(options)
  #        # install a mysql server and set the root password to options[:root_password]
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
    attr_reader :catalog
    class_inheritable_accessor :__config__
    write_inheritable_attribute(:__config__, Hash.new)

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

      configure(config)
      @executed = false
      @catalog = Puppet::Resource::Catalog.new
      @catalog.host_config = false
      @catalog.name = self.name
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
      return nil if methods.nil? || methods == [] # TODO can probably replace with if methods.blank?
      options = methods.extract_options!
      methods.each do |meth|
        options = configuration[meth.to_sym] if options == {} # TODO can probably be replaced with options.blank?
        options ||= {}
        recipes << [meth.to_sym, options]
      end
    end

    # Access to a recipe of the class of this instance.
    #
    #   class SampleManifest < ShadowPuppet::Manifest
    #     def my_recipe
    #       recipe :other_recipe
    #     end
    #   end
    def recipe(*methods)
      self.class.recipe *methods
    end

    # A HashWithIndifferentAccess describing any configuration that has been
    # performed on the class. Modify this hash by calling configure:
    #
    #   class SampleManifest < ShadowPuppet::Manifest
    #     configure(:name => 'test')
    #   end
    #
    #   >> SampleManifest.configuration
    #   => {:name => 'test'}
    #    #
    # Subclasses of the Manifest class properly inherit the parent classes'
    # configuration.
    def self.configuration
      __config__.with_indifferent_access
    end

    # Access to the configuration of the class of this instance.
    #
    #   class SampleManifest < ShadowPuppet::Manifest
    #     configure(:name => 'test')
    #   end
    #
    #   @manifest = SampleManifest.new
    #   @manifest.configuration[:name] => "test"
    def configuration
      self.class.configuration
    end

    # Define configuration on this manifest. This is useful for storing things
    # such as hostnames, password, or usernames that may change between
    # different implementations of a shared manifest. Access this hash by
    # calling <tt>configuration</tt>:
    #
    #   class SampleManifest < ShadowPuppet::Manifest
    #     configure('name' => 'test')
    #   end
    #
    #   >> SampleManifest.configuration
    #   => {:name => 'test'}
    #    #
    # Subsequent calls to configure perform a deep_merge of the provided
    # <tt>hash</tt> into the pre-existing configuration.
    def self.configure(hash)
      __config__.replace(__config__.deep_symbolize_keys.deep_merge(hash.deep_symbolize_keys))
    end

    # Update the configuration of this manifest instance's class.
    #
    #   class SampleManifest < ShadowPuppet::Manifest
    #     configure({})
    #   end
    #
    #   @manifest = SampleManifest.new
    #   @manifest.configure(:name => "test")
    #   @manifest.configuration[:name] => "test"
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
        # remove the method rdoc placeholders
        remove_method(type.name) rescue nil
        define_method(type.name) do |*args|
          if args && args.flatten.size == 1
            reference(type, args.first)
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

    def missing_recipes
      missing = self.class.recipes.each do |meth,args|
        !respond_to?(meth)
      end
    end

    # Execute this manifest, applying all resources defined. Execute returns
    # true if successfull, and false if unsucessfull. By default, this
    # will only execute a manifest that has not already been executed?.
    # The +force+ argument, if true, removes this check.
    def execute(force=false)
      return false if executed? && !force
      evaluate_recipes
      apply
    rescue Exception => e
      false
    else
      true
    ensure
      @executed = true
    end

    # Execute this manifest, applying all resources defined. Execute returns
    # true if successfull, and raises an exception if not. By default, this
    # will only execute a manifest that has not already been executed?.
    # The +force+ argument, if true, removes this check.
    def execute!(force=false)
      return false if executed? && !force
      evaluate_recipes
      apply
    rescue Exception => e
      raise e
    else
      true
    ensure
      @executed = true
    end

    def graph_to(name, destination)
      evaluate_recipes

      relationship_graph = @catalog.relationship_graph

      graph = relationship_graph.to_dot_graph("name" => "#{name} Relationships".gsub(/\W+/, '_'))
      graph.options['label'] = "#{name} Relationships"

      # The graph ends up having all of the edges backwards
      graph.each_node do |node|
        next unless node.is_a?(DOT::DOTEdge)
        node.to, node.from = node.from, node.to
      end

      File.open(destination, "w") { |f|
          f.puts graph.to_s
      }
    end

    protected

    #Has this manifest instance been executed?
    def executed?
      @executed
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
    def apply
      catalog.apply
      catalog.clear
    end

    # Create a reference to another Puppet Resource.
    def reference(type, name, params = {})
      Puppet::Parser::Resource::Reference.new(type.name.to_s.capitalize, name.to_s)
    end

    # Creates a new Puppet Resource and adds it to the Catalog.
    def new_resource(type, title, params = {})
      params.merge!({:title   => title})
      params.merge!({:catalog => catalog})
      params.merge!({:path    => ENV["PATH"]}) if type.name == :exec && params[:path].nil?
      params.merge!({:cwd     => params[:cwd].to_s}) unless params[:cwd].respond_to?(:=~)
      catalog.add_resource(Puppet::Type.type(type.name).new(params))
    end
  end
end
