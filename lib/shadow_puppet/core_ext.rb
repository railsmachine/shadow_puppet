require 'active_support'
require 'active_support/version'

# ActiveSupport 3 doesn't automatically load core_ext anymore
if ActiveSupport::VERSION::MAJOR >= 3
  require 'active_support/deprecation'
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

# backport inheritable accessors deprecated in 3.1 and removed in 3.2
if (ActiveSupport::VERSION::MAJOR == 3 and ActiveSupport::VERSION::MINOR >= 1) or ActiveSupport::VERSION::MAJOR > 3
  class Class
    def class_inheritable_reader(*syms)
      syms.each do |sym|
        next if sym.is_a?(Hash)
        class_eval <<-EOS
          def self.#{sym}                        # def self.before_add_for_comments
            read_inheritable_attribute(:#{sym})  #   read_inheritable_attribute(:before_add_for_comments)
          end                                    # end
                                                 #
          def #{sym}                             # def before_add_for_comments
            self.class.#{sym}                    #   self.class.before_add_for_comments
          end                                    # end
        EOS
      end
    end

    def class_inheritable_writer(*syms)
      options = syms.extract_options!
      syms.each do |sym|
        class_eval <<-EOS
          def self.#{sym}=(obj)                          # def self.color=(obj)
            write_inheritable_attribute(:#{sym}, obj)    #   write_inheritable_attribute(:color, obj)
          end                                            # end
                                                         #
          #{"                                            #
          def #{sym}=(obj)                               # def color=(obj)
            self.class.#{sym} = obj                      #   self.class.color = obj
          end                                            # end
          " unless options[:instance_writer] == false }  # # the writer above is generated unless options[:instance_writer] == false
        EOS
      end
    end

    def class_inheritable_accessor(*syms)
      class_inheritable_reader(*syms)
      class_inheritable_writer(*syms)
    end

    def inheritable_attributes
      @inheritable_attributes ||= EMPTY_INHERITABLE_ATTRIBUTES
    end

    def write_inheritable_attribute(key, value)
      if inheritable_attributes.equal?(EMPTY_INHERITABLE_ATTRIBUTES)
        @inheritable_attributes = {}
      end
      inheritable_attributes[key] = value
    end

    def read_inheritable_attribute(key)
      inheritable_attributes[key]
    end

    def reset_inheritable_attributes
      @inheritable_attributes = EMPTY_INHERITABLE_ATTRIBUTES
    end

    private
      # Prevent this constant from being created multiple times
      EMPTY_INHERITABLE_ATTRIBUTES = {}.freeze unless const_defined?(:EMPTY_INHERITABLE_ATTRIBUTES)

      def inherited_with_inheritable_attributes(child)
        inherited_without_inheritable_attributes(child) if respond_to?(:inherited_without_inheritable_attributes)

        if inheritable_attributes.equal?(EMPTY_INHERITABLE_ATTRIBUTES)
          new_inheritable_attributes = EMPTY_INHERITABLE_ATTRIBUTES
        else
          new_inheritable_attributes = inheritable_attributes.inject({}) do |memo, (key, value)|
            memo.update(key => value.duplicable? ? value.dup : value)
          end
        end

        child.instance_variable_set('@inheritable_attributes', new_inheritable_attributes)
      end

      alias inherited_without_inheritable_attributes inherited
      alias inherited inherited_with_inheritable_attributes
  end
end
