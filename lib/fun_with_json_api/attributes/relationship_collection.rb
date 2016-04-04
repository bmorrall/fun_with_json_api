require 'fun_with_json_api/schema_validators/check_collection_is_authorized'

module FunWithJsonApi
  module Attributes
    class RelationshipCollection < FunWithJsonApi::Attribute
      def self.create(name, deserializer_class_or_callable, options = {})
        new(name, deserializer_class_or_callable, options)
      end

      attr_reader :deserializer_class
      attr_reader :options
      delegate :type, to: :deserializer

      def initialize(name, deserializer_class, options = {})
        options = options.reverse_merge(
          attributes: [],
          relationships: []
        )
        super(name, options)
        @deserializer_class = deserializer_class
      end

      # Expects an array of id values for a nested collection
      def decode(values)
        unless values.nil? || values.is_a?(Array)
          raise build_invalid_relationship_collection_error(values)
        end

        collection = deserializer.load_collection_from_id_values(values)

        # Ensure the collection size matches
        check_collection_matches_values!(collection, values)

        # Ensure the user is authorized to access the collection
        check_collection_is_authorized!(collection, values)

        # Call ActiceRecord#pluck if it is available
        convert_collection_to_ids(collection)
      end

      # rubocop:disable Style/PredicateName

      def has_many?
        true
      end

      # rubocop:enable Style/PredicateName

      # User the singular of `as` that is how AMS converts the value
      def param_value
        :"#{as.to_s.singularize}_ids"
      end

      def deserializer
        @deserializer ||= build_deserializer_from_options
      end

      private

      def build_deserializer_from_options
        if @deserializer_class.respond_to?(:call)
          @deserializer_class.call
        else
          @deserializer_class
        end.create(options)
      end

      def check_collection_matches_values!(collection, values)
        expected_size = values.size
        result_size = collection.size
        if result_size != expected_size
          raise build_missing_relationship_error_from_collection(collection, values)
        end
      end

      def check_collection_is_authorized!(collection, values)
        SchemaValidators::CheckCollectionIsAuthorised.call(
          collection, values, deserializer, prefix: "/data/relationships/#{name}/data"
        )
      end

      def convert_collection_to_ids(collection)
        if collection.respond_to? :pluck
          # Well... pluck+arel doesn't work with SQLite, but select at least is safe
          collection = collection.select(deserializer.resource_class.arel_table[:id])
        end
        collection.map(&:id)
      end

      def build_invalid_relationship_collection_error(values)
        exception_message = "#{name} relationship should contain a array of"\
                            " '#{deserializer.type}' data"
        payload = ExceptionPayload.new
        payload.pointer = "/data/relationships/#{name}"
        payload.detail = exception_message
        Exceptions::InvalidRelationship.new(exception_message + ": #{values.inspect}", payload)
      end

      def build_missing_relationship_error_from_collection(collection, values)
        collection_ids = deserializer.format_collection_ids(collection)

        payload = build_missing_relationship_payload(collection_ids, values)

        missing_values = values.reject { |value| collection_ids.include?(value.to_s) }
        exception_message = "Couldn't find #{deserializer.resource_class} items with "\
                            "#{deserializer.id_param} in #{missing_values.inspect}"
        Exceptions::MissingRelationship.new(exception_message, payload)
      end

      def build_missing_relationship_payload(collection_ids, values)
        values.each_with_index.map do |resource_id, index|
          next if collection_ids.include?(resource_id)

          ExceptionPayload.new.tap do |payload|
            payload.pointer = "/data/relationships/#{name}/data/#{index}"
            payload.detail = "Unable to find '#{deserializer.type}' with matching id"\
                             ": \"#{resource_id}\""
            payload.status = '410' if deserializer.resource_is_soft_deleted?(resource_id)
          end
        end.reject(&:nil?)
      end
    end
  end
end
