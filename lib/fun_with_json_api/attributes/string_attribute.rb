module FunWithJsonApi
  module Attributes
    class StringAttribute < Attribute
      def decode(value)
        return value if value.nil? || value.is_a?(String)

        raise build_invalid_attribute_error(value)
      end

      def encode(resource)
        value = super(resource)
        value.nil? ? nil : value.to_s
      end

      private

      def build_invalid_attribute_error(value)
        payload = ExceptionPayload.new
        payload.detail = I18n.t('fun_with_json_api.exceptions.invalid_string_attribute')
        payload.pointer = "/data/attributes/#{name}"
        Exceptions::InvalidAttribute.new("Value is not a string: #{value.class.name}", payload)
      end
    end
  end
end
