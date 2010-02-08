module Puppet
  module Parser
    class Resource

      # clearing out some puppet methods that we probably won't need for testing
      # that are also used in the params hash when defining the resource.
      undef path
      undef source
      undef require
      
      # This allows access to resource options as methods on the resource.
      def method_missing name, *args
        if params.keys.include? name.to_sym
          params[name.to_sym].value
        end
      end
    end
  end
end

module ShadowPuppet
  # To test manifests, access puppet resources using the plural form of the resource name.
  # This returns a hash of all resources of that type.
  #
  #   manifest.execs
  #   manifest.packages
  #
  # You can access resource options as methods on the resource
  #
  #   manifest.files['/etc/motd'].content
  #   manifest.execs['service ssh restart'].onlyif
  #
  # === Example
  #
  # Given this manifest:
  #
  #   class TestManifest < ShadowPuppet::Manifest
  #     def myrecipe
  #       file '/etc/motd', :content => 'Welcome to the machine!', :mode => '644'
  #       exec 'newaliases', :refreshonly => true
  #     end
  #     recipe :myrecipe
  #   end
  #
  # A test for the manifest could look like this:
  #  
  #   manifest = TestManifest.new
  #   manifest.myrecipe
  #   assert_match /Welcome/, manifest.files['/etc/motd']
  #   assert manifest.execs['newaliases'].refreshonly
  #
  class Manifest
    # Creates an instance method for every puppet type 
    # that either creates or references a resource
    def self.register_puppet_types_for_testing
      Puppet::Type.loadall
      Puppet::Type.eachtype do |type|
        plural_type = type.name.to_s.downcase.pluralize
        #undefine the method rdoc placeholders
        undef_method(plural_type) rescue nil
        define_method(plural_type) do |*args|
          puppet_resources[type]
        end
      end
    end
    register_puppet_types_for_testing
    
  end
end
