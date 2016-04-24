module FunWithJsonAPi
  module ActiveModelSerializers
    # Builds an options hash for ActiveModelSerializers::Deserialization.jsonapi_parse
    class DeserializerConfigBuilder
      def self.build(json_api_resource)
        new(json_api_resource).build
      end

      private_class_method :new

      attr_reader :json_api_resource

      def initialize(json_api_resource)
        @json_api_resource = json_api_resource
      end

      def build
        {
          only: build_only_values,
          keys: build_keys_value
        }
      end

      protected

      def build_only_values
        attribute_only_values(json_api_resource.attributes) +
          attribute_only_values(json_api_resource.relationships)
      end

      def build_keys_value
        Hash[
          attribute_key_values(json_api_resource.attributes) +
          attribute_key_values(json_api_resource.relationships)
        ]
      end

      private

      def attribute_only_values(attributes_or_relationships)
        attributes_or_relationships.map(&:name)
      end

      def attribute_key_values(attributes_or_relationships)
        attributes_or_relationships.select { |a| a.name != a.as }
                                   .map { |a| [a.name, a.as] }
      end
    end
  end
end
