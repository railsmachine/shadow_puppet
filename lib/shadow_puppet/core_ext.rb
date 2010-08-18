require 'active_support/version'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/core_ext/array'
require 'active_support/inflector'
require 'active_support/core_ext/class/inheritable_attributes'

# zomg epic hax
if ActiveSupport::VERSION::MAJOR < 3
  if ActiveSupport::VERSION::TINY > 5
    # hack around absurd number of deprecation warnings from puppet
    # using `metaclass`
    require 'active_support/core_ext/kernel/reporting'
    require 'active_support/core_ext/module/attribute_accessors'
    require 'active_support/deprecation'
    ActiveSupport::Deprecation.silenced = true
  end
  require 'active_support/core_ext/string/inflections'
  unless String.included_modules.include?(ActiveSupport::CoreExtensions::String::Inflections)
    String.send :include, ActiveSupport::CoreExtensions::String::Inflections
  end
  require 'active_support/core_ext/duplicable'
else
  require 'active_support/core_ext/object/duplicable'
end

class Hash #:nodoc:
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
