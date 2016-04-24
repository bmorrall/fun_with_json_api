require 'active_model_serializers'
require 'fun_with_json_api/active_model_serializers/deserializer_config_builder'

module FunWithJsonApi
  module ActiveModelSerializers
    # Converts a json_api document into a rails compatible hash.
    # Acts as an adaptor for ActiveModuleSerializer json_api_resource classes
    class PreDeserializer
      def self.parse(*args)
        new(*args).parse
      end

      attr_reader :document
      attr_reader :json_api_resource

      def initialize(json_api_resource, document)
        @json_api_resource = json_api_resource
        @document = document.to_h.deep_dup.deep_stringify_keys
      end

      def parse
        ams_deserializer_class.parse(document, ams_deserializer_config) do |invalid_document, reason|
          exception_message = "Invalid payload (#{reason}): #{invalid_document}"
          exception = convert_reason_into_exceptions(exception_message, reason).first ||
                      Exceptions::InvalidDocument.new(exception_message)
          raise exception
        end
      end

      protected

      def convert_reason_into_exceptions(exception_message, reason, values = [])
        if reason.is_a?(String)
          return convert_reason_message_into_error(exception_message, reason, values.join)
        end
        return nil unless reason.is_a?(Hash)
        return nil unless reason.size == 1

        reason.flat_map do |key, value|
          convert_reason_into_exceptions(exception_message, value, (values + ["/#{key}"]))
        end
      end

      def convert_reason_message_into_error(exception_message, reason, source)
        payload = ExceptionPayload.new
        payload.pointer = source.presence
        payload.detail = reason
        Exceptions::InvalidDocument.new(exception_message, payload)
      end

      def ams_deserializer_class
        if defined?(::ActiveModel::Serializer::Adapter::JsonApi::Deserialization)
          ::ActiveModel::Serializer::Adapter::JsonApi::Deserialization
        else
          ::ActiveModelSerializers::Adapter::JsonApi::Deserialization
        end
      end

      def ams_deserializer_config
        @ams_deserializer_config ||=
          FunWithJsonAPi::ActiveModelSerializers::DeserializerConfigBuilder.build(json_api_resource)
      end
    end
  end
end
