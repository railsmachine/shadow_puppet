require 'puppet'
require 'puppet/dsl'
require 'erb'
gem "activesupport"
require 'active_support'

class Puppet::Util::Log
  @loglevel = 0
end

class Puppet::DSL::Aspect
  def reference(type, title)
    Puppet::Parser::Resource::Reference.new(:type => type.to_s, :title => title.to_s)
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
        reference(type.name, args.first)
      else
        newresource(type, *args)
      end
    end
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

    def run?
      @run
    end

    def self.role(name, options = {}, &block)
      a = Puppet::DSL::Aspect.new(name, options, &block)
      self.aspects << a
      a
    end

    def manifest
      self
    end

    def run
      role_names = aspects.map { |r| r.name }
      run_roles(*role_names) if role_names
    end

    def role(name, options = {}, &block)
      a = Puppet::DSL::Aspect.new(name, options, &block)
      @instance_aspects << a
      a
    end

    def aspects
      self.class.aspects + instance_aspects
    end

    def run_roles(*names)
      raise Exception if run?
      acquire(*names)
      b = apply
      @run = true
    end

    def apply
        bucket = export()
        catalog = bucket.to_catalog
        catalog.apply
    end

    def acquire(*names)
        names.each do |name|
            if aspect = Puppet::DSL::Aspect[name]
                unless aspect.evaluated?
                    aspect.evaluate
                end
            else
                raise "Could not find aspect %s" % name
            end
        end
    end

    def export
      objects = aspects.map{ |r| [r.name, r] }.collect do |name, aspect|
          if aspect.evaluated?
              aspect.export
          end
      end.reject { |a| a.nil? }.flatten.collect do |obj|
          obj.to_trans
      end
      bucket = Puppet::TransBucket.new(objects)
      bucket.name = "moonshine.#{Time.new.to_f.to_s.gsub(/\./,'')}"
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