require 'active_support/version'

require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/core_ext/array'
require 'active_support/inflector'
require 'active_support/core_ext/class/inheritable_attributes'

if ActiveSupport::VERSION::MAJOR < 3
  require 'active_support/core_ext/duplicable'
else
  require 'active_support/core_ext/object/duplicable'
end

require 'active_support/core_ext/hash/indifferent_access'

class Hash #:nodoc:
  # activesupport 3 automatically includes indifferent access... yay?
  include ActiveSupport::CoreExtensions::Hash::IndifferentAccess if ActiveSupport::VERSION::MAJOR < 3

  def deep_merge(other_hash)
    self.merge(other_hash) do |key, oldval, newval|
      oldval = oldval.to_hash if oldval.respond_to?(:to_hash)
      newval = newval.to_hash if newval.respond_to?(:to_hash)
      oldval.is_a?(Hash) && newval.is_a?(Hash) ? oldval.deep_merge(newval) : newval
    end
  end

  def deep_merge!(other_hash)
    replace(deep_merge(other_hash))
  end
  
  def deep_symbolize_keys
    self.inject({}) { |result, (key, value)|
      value = value.deep_symbolize_keys if value.is_a?(Hash)
      result[(key.to_sym rescue key) || key] = value
      result
    }
  end
end

