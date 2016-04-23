module FunWithJsonApi
  module Attributes
    class Relationship < FunWithJsonApi::Attribute
      # Creates a new Relationship with name
      # @param name [String] name of the relationship
      # @param deserializer_class_or_callable [Class] Class of Deserializer or
      #   a callable that returns one
      # @param options[at] [String] alias value for the attribute
      def self.create(name, deserializer_class_or_callable, options = {})
        new(name, deserializer_class_or_callable, options)
      end

      attr_reader :deserializer_class
      delegate :type, to: :deserializer

      def initialize(name, deserializer_class, options = {})
        options = options.reverse_merge(
          # attributes: [],
          relationships: []
        )
        super(name, options)
        @deserializer_class = deserializer_class
      end

      def decode(id_value)
        unless id_value.nil? || !id_value.is_a?(Array)
          raise build_invalid_relationship_error(id_value)
        end

        resource = deserializer.load_resource_from_id_value(id_value)
        raise build_missing_relationship_error(id_value) if resource.nil?

        check_resource_is_authorized!(resource, id_value)

        resource.id
      end

      # rubocop:disable Style/PredicateName

      def has_many?
        false
      end

      # rubocop:enable Style/PredicateName

      def param_value
        :"#{as}_id"
      end

      def deserializer
        @deserializer ||= build_deserializer_from_options
      end

      private

      def check_resource_is_authorized!(resource, id_value)
        SchemaValidators::CheckResourceIsAuthorised.call(
          resource, id_value, deserializer, resource_pointer: "/data/relationships/#{name}"
        )
      end

      def build_deserializer_from_options
        if @deserializer_class.respond_to?(:call)
          @deserializer_class.call
        else
          @deserializer_class
        end.create(options)
      end

      def build_invalid_relationship_error(id_value)
        exception_message = "#{name} relationship should contain a single '#{deserializer.type}'"\
                            ' data hash'
        payload = ExceptionPayload.new
        payload.pointer = "/data/relationships/#{name}"
        payload.detail = exception_message
        Exceptions::InvalidRelationship.new(exception_message + ": #{id_value.inspect}", payload)
      end

      def build_missing_relationship_error(id_value, message = nil)
        message ||= missing_resource_debug_message(id_value)
        payload = ExceptionPayload.new
        payload.pointer = "/data/relationships/#{name}"
        payload.detail = "Unable to find '#{deserializer.type}' with matching id"\
                         ": #{id_value.inspect}"
        Exceptions::MissingRelationship.new(message, payload)
      end

      def missing_resource_debug_message(id_value)
        "Couldn't find #{deserializer.resource_class.name}"\
        " where #{deserializer.id_param} = #{id_value.inspect}"
      end
    end
  end
end
