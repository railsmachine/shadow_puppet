require 'active_support/version'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/core_ext/array'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/hash/indifferent_access'
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
  end
  require 'active_support/core_ext/string/inflections'
  unless String.included_modules.include?(ActiveSupport::CoreExtensions::String::Inflections)
    String.send :include, ActiveSupport::CoreExtensions::String::Inflections
  end
  require 'active_support/core_ext/duplicable'
  class Hash #:nodoc:
    include ActiveSupport::CoreExtensions::Hash::DeepMerge
    include ActiveSupport::CoreExtensions::Hash::IndifferentAccess
  end
else
  require 'active_support/core_ext/object/duplicable'
end

ActiveSupport::Deprecation.silenced = true

class Hash #:nodoc:
  def deep_symbolize_keys
    self.inject({}) { |result, (key, value)|
      value = value.deep_symbolize_keys if value.is_a?(Hash)
      result[(key.to_sym rescue key) || key] = value
      result
    }
  end
end
