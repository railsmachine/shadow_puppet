require 'puppet'
require 'puppet/dsl'
require 'erb'
gem "activesupport"
require 'active_support'

class Puppet::DSL::Aspect

  def initialize(name, options = {}, &block)
    @name = symbolize(name)
    if block
      @block = block
    end
    if pname = options[:inherits]
      if pname.is_a?(self.class)
        @parent = pname
      elsif parent = self.class[pname]
        @parent = parent
      else
        raise "Could not find parent aspect %s" % pname
      end
    end

    @resources = []

    self.class[name] = self
  end

  def reference(type, title)
    Puppet::Parser::Resource::Reference.new(:type => type.to_s, :title => title.to_s, :scope => scope)
  end

  def facts
    Facter.flush
    Facter.to_hash
  end

  #Create an instance method for every type that either creates or references
  #a resource
  Puppet::Type.loadall
  Puppet::Type.eachtype do |type|
    undef_method(type.name)
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

end

#    class UrServer < Moonshine::Manifest
#      role :something_else do
#        exec "foo", :command => "echo 'normal puppet stuff here' > /tmp/test"
#      end
#    end
#    server = UrServer.new("name_of_application")
#    server.run
module Moonshine
  class Manifest

    attr_reader :application
    attr_reader :instance_aspects
    class_inheritable_accessor :aspects
    self.aspects = []

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
      @instance_aspects = []
      @run = false
    end

    def self.role(name, options = {}, &block)
      a = Puppet::DSL::Aspect.new(name, options, &block)
      self.aspects << a
      a
    end

    def role(name, options = {}, &block)
      a = Puppet::DSL::Aspect.new(name, options, &block)
      @instance_aspects << a
      a
    end

    def aspects
      self.class.aspects + instance_aspects
    end

    def aspect(name)
      begin
        self.aspects.detect { |a| a.name.to_sym == name.to_sym }
      rescue
        nil
      end
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
      role_names = aspects.map { |r| r.name }
      run_roles(*role_names) if role_names
    end

    def run_roles(*names)
      raise Exception if run?
      bucket = evaluate_and_export(*names)
      catalog = bucket.to_catalog
      applied_catalog = catalog.apply
      @run = true
      applied_catalog
    end

    def evaluate_and_export(*names)
      #evaluate
      evaluated_aspects = []
      names.each do |name|
        if aspect = aspect(name)
          unless aspect.evaluated?
            aspect.evaluate
            evaluated_aspects << aspect
          end
        else
          raise "Could not find aspect %s" % name
        end
      end

      #export
      objects_for_export = []
      objects = evaluated_aspects.collect do |aspect|
        if aspect.evaluated?
          evaluated_aspect = aspect.export
          objects_for_export << evaluated_aspect unless evaluated_aspect.nil?
        end
      end
      trans_objects = objects.flatten.collect do |obj|
        obj.to_trans
      end
      bucket = Puppet::TransBucket.new(trans_objects)
      bucket.name = "moonshine:#{object_id}"
      bucket.type = "class"

      return bucket
    end
  end

end

Dir.glob(File.join(File.dirname(__FILE__), '..', 'facts', '*.rb')).each do |fact|
  require fact
end
Dir.glob(File.join(File.dirname(__FILE__), 'modules', '*.rb')).each do |mod|
  require mod
end
Dir.glob(File.join(File.dirname(__FILE__), 'manifest', '*.rb')).each do |manifest|
  require manifest
end