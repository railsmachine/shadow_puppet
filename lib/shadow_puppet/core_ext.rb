require 'active_support'
require 'active_support/version'

# ActiveSupport 3 doesn't automatically load core_ext anymore
if ActiveSupport::VERSION::MAJOR == 3
  require 'active_support/core_ext'
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
