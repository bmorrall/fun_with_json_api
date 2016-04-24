module FunWithJsonApi
  module ActiveModelSerializers
    class SerializerGenerator
      def self.call(json_api_resource_or_class, json_api_resource_options = {})
        new(json_api_resource_or_class, json_api_resource_options).call
      end

      private_class_method :new

      attr_reader :json_api_resource
      attr_reader :known_serializers

      def initialize(json_api_resource_or_class, json_api_resource_options, known_serializers = {})
        @json_api_resource = FunWithJsonApi.build_json_api_resource(
          json_api_resource_or_class, json_api_resource_options
        )
        @known_serializers = known_serializers
      end

      def call
        serializer = build_serializer_class
        known_serializers[json_api_resource_class] = serializer

        serializer.type(json_api_resource.type)
        json_api_resource.attributes.each do |attribute|
          add_attribute(serializer, attribute)
        end
        json_api_resource.relationships.each do |relationship|
          add_relationship(serializer, relationship)
        end
        serializer
      end

      def json_api_resource_class
        json_api_resource.class
      end

      private

      def build_serializer_class
        serializer = Class.new(::ActiveModel::Serializer) do
          class << self
            attr_accessor :fun_with_json_api_id_attribute
          end

          def id
            object.send self.class.fun_with_json_api_id_attribute.as
          end
        end
        serializer.fun_with_json_api_id_attribute = json_api_resource.id_attribute
        serializer
      end

      def add_attribute(serializer, attribute)
        json_api_resource = self.json_api_resource
        serializer.attribute(attribute.name) do
          json_api_resource.public_send(attribute.encode_attribute_method, object)
        end
      end

      def add_relationship(serializer, relationship)
        if relationship.has_many?
          add_has_many_relationship(serializer, relationship)
        else
          add_belongs_to_relationship(serializer, relationship)
        end
      end

      def add_has_many_relationship(serializer, relationship)
        relationship_serializer = build_relationship_serializer(relationship)
        json_api_resource = self.json_api_resource
        serializer.has_many(relationship.name, serializer: relationship_serializer) do
          json_api_resource.public_send(relationship.encode_attribute_method, object)
        end
      end

      def add_belongs_to_relationship(serializer, relationship)
        relationship_serializer = build_relationship_serializer(relationship)
        json_api_resource = self.json_api_resource
        serializer.belongs_to(relationship.name, serializer: relationship_serializer) do
          json_api_resource.public_send(relationship.encode_attribute_method, object)
        end
      end

      def build_relationship_serializer(relationship)
        relationship_json_api_resource = relationship.json_api_resource
        relationship_json_api_resource_class = relationship_json_api_resource.class
        known_serializers.fetch(relationship_json_api_resource_class) do
          self.class.send(:new, relationship_json_api_resource, nil, known_serializers).call
        end
      end
    end
  end
end
