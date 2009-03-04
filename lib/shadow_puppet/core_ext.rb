require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/core_ext/array'
require 'active_support/inflector'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/class/inheritable_attributes'
require 'active_support/core_ext/duplicable'
class Hash #:nodoc:
  include ActiveSupport::CoreExtensions::Hash::IndifferentAccess

  # Returns a new hash with +self+ and +other_hash+ merged recursively.
  def deep_merge(other_hash)
    self.merge(other_hash) do |key, oldval, newval|
      oldval = oldval.to_hash if oldval.respond_to?(:to_hash)
      newval = newval.to_hash if newval.respond_to?(:to_hash)
      oldval.class.to_s == 'Hash' && newval.class.to_s == 'Hash' ? oldval.deep_merge(newval) : newval
    end
  end

  # Returns a new hash with +self+ and +other_hash+ merged recursively.
  # Modifies the receiver in place.
  def deep_merge!(other_hash)
    replace(deep_merge(other_hash))
  end
end