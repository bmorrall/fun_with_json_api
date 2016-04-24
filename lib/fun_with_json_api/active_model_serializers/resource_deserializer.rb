require 'fun_with_json_api/active_model_serializers/pre_deserializer'
require 'fun_with_json_api/schema_validator'

module FunWithJsonApi
  module ActiveModelSerializers
    class ResourceDeserializer
      attr_reader :json_api_resource

      def initialize(json_api_resource_or_class, json_api_resource_options = {})
        @json_api_resource = FunWithJsonApi.build_json_api_resource(
          json_api_resource_or_class, json_api_resource_options
        )
      end

      def deserialize(document, resource_or_nil = nil)
        # Run through initial document structure validation and deserialization
        unfiltered = FunWithJsonApi::ActiveModelSerializers::PreDeserializer.parse(
          json_api_resource, document
        )

        # Check the document matches up with expected resource parameters
        FunWithJsonApi::SchemaValidator.check(json_api_resource, document, resource_or_nil)

        # Ensure document matches schema, and sanitize values
        decode_param_values(unfiltered)
      end

      private

      # Takes a parsed params hash from ActiveModelSerializers::Deserialization and sanitizes values
      def decode_param_values(params)
        Hash[
          decode_attribute_values(json_api_resource.attributes, params) +
          decode_attribute_values(json_api_resource.relationships, params)
        ]
      end

      # Calls <attribute.as> on the current instance, override the #<as> method to change loading
      def decode_attribute_values(attributes, params)
        attributes.select { |attribute| params.key?(attribute.param_value) }
                  .map { |attribute| decode_attribute(attribute, params) }
      end

      # Calls <attribute.as> on the current instance, override the #<as> method to change loading
      def decode_attribute(attribute, params)
        encoded_value = params.fetch(attribute.param_value)
        [
          attribute.param_value,
          json_api_resource.public_send(attribute.decode_attribute_method, encoded_value)
        ]
      end
    end
  end
end
