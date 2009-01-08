require 'puppet'
require 'puppet/dsl'
require 'erb'
gem "activesupport"
require 'active_support'

class Puppet::DSL::Aspect
  attr_accessor :uniq_id
  attr_accessor :parent_uniq_id

  def initialize(name, options = {}, &block)
    if @uniq_id = options[:id]
      @name = symbolize(uniquify(name))
    else
      @name = symbolize(name)
    end
    @parent_uniq_id = options[:parent_id]
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
    Puppet::Parser::Resource::Reference.new(:type => type.to_s, :title => title.to_s)
  end

  def scoped_reference(type,title)
    reference(type,uniquify(title))
  end

  def class_reference(type,title)
    reference(type,uniquify(title, :parent_uniq_id))
  end

  def uniquify(name = '', method = :uniq_id)
    return name if self.send(method).nil?
    (self.send(method).to_s + ':' + name.to_s)
  end

  def facts
    Facter.to_hash
  end

  #Create an instance method for every type that either creates or references
  #a resource
  Puppet::Type.loadall
  Puppet::Type.eachtype do |type|
    undef_method(type.name)
    define_method(type.name) do |*args|
      if args && args.flatten.size == 1
        scoped_reference(type.name, args.first)
      else
        scoped_resource(type, args.first, args.last)
      end
    end
  end

  def scoped_resource(type, name, params = {})
    newresource(type, uniquify(name), params)
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
      a = Puppet::DSL::Aspect.new(name, options.merge({:id => object_id}), &block)
      self.aspects << a
      a
    end

    def role(name, options = {}, &block)
      a = Puppet::DSL::Aspect.new(name, options.merge({:id => object_id, :parent_id => self.class.object_id}), &block)
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