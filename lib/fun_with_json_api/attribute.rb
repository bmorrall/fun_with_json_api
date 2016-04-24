module FunWithJsonApi
  class Attribute
    attr_reader :name
    attr_reader :as
    attr_reader :options

    def self.create(name, options = {})
      format = options.fetch(:format, 'string')
      attribute_class_name = "#{format.to_s.classify}Attribute"
      if FunWithJsonApi::Attributes.const_defined?(attribute_class_name)
        FunWithJsonApi::Attributes.const_get(attribute_class_name)
      else
        raise ArgumentError, "Unknown attribute type: #{format}"
      end.new(name, options)
    end

    def initialize(name, options = {})
      raise ArgumentError, 'name cannot be blank!' unless name.present?

      @name = name.to_sym
      @as = options.fetch(:as, name).to_sym
      @options = options
    end

    def decode(value)
      value
    end
    alias call decode

    def encode(resource)
      resource.public_send(as)
    end

    def decode_attribute_method
      :"decode_#{name}"
    end

    def encode_attribute_method
      :"encode_#{name}"
    end

    def param_value
      as
    end
  end
end

# Load pre-defined Attributes
Dir["#{File.dirname(__FILE__)}/attributes/**/*.rb"].each { |f| require f }
