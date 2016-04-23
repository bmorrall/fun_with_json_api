module FunWithJsonApi
  module ActiveModelSerializers
    class SerializerGenerator
      def self.call(deserializer)
        new(deserializer).call
      end

      attr_reader :deserializer
      attr_reader :known_serializers

      def initialize(deserializer_class, known_serializers = {})
        @deserializer = deserializer_class
        @known_serializers = known_serializers
      end

      def call
        serializer = build_serializer_class
        known_serializers[deserializer_class] = serializer

        serializer.type(deserializer.type)
        deserializer.attributes.each do |attribute|
          add_attribute(serializer, attribute)
        end
        deserializer.relationships.each do |relationship|
          add_relationship(serializer, relationship)
        end
        serializer
      end

      private

      def deserializer_class
        @deserializer_class ||= deserializer.is_a?(Class) ? deserializer : deserializer.class
      end

      def id_attribute
        deserializer.attributes.detect do |attribute|
          attribute.name == :id
        end || Attribute.create(:id, as: deserializer.id_param)
      end

      def build_serializer_class
        serializer = Class.new(ActiveModel::Serializer) do
          class << self
            attr_accessor :fun_with_json_api_id_attribute
          end

          def id
            object.send self.class.fun_with_json_api_id_attribute.as
          end
        end
        serializer.fun_with_json_api_id_attribute = id_attribute
        serializer
      end

      def add_attribute(serializer, attribute)
        serializer.attribute(attribute.name) do
          value = object.public_send(attribute.as)
          attribute.encode(value)
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
        serializer.has_many(relationship.name, serializer: relationship_serializer) do
          value = object.public_send(relationship.as)
          relationship.encode(value)
        end
      end

      def add_belongs_to_relationship(serializer, relationship)
        relationship_serializer = build_relationship_serializer(relationship)
        serializer.belongs_to(relationship.name, serializer: relationship_serializer) do
          value = object.public_send(relationship.as)
          relationship.encode(value)
        end
      end

      def build_relationship_serializer(relationship)
        relationship_deserializer = relationship.deserializer
        relationship_deserializer_class = relationship_deserializer.class
        known_serializers.fetch(relationship_deserializer_class) do
          self.class.new(relationship_deserializer, known_serializers).call
        end
      end
    end
  end
end
