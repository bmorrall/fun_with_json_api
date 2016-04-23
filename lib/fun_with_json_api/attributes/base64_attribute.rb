module FunWithJsonApi
  module Attributes
    class Base64Attribute < Attribute
      def call(value)
        require 'base64'

        if value.nil?
          nil
        elsif value.is_a?(String)
          Base64.decode64(value)
        else
          raise build_invalid_attribute_error(value)
        end
      end

      private

      def build_invalid_attribute_error(value)
        payload = ExceptionPayload.new
        payload.detail = I18n.t('fun_with_json_api.exceptions.invalid_base64_attribute')
        payload.pointer = "/data/attributes/#{name}"
        Exceptions::InvalidAttribute.new(
          "Value is not a Base64 encoded string: #{value.class.name}", payload
        )
      end
    end
  end
end
