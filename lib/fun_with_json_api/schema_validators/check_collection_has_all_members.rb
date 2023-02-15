require 'fun_with_json_api/exception'

module FunWithJsonApi
  module SchemaValidators
    class CheckCollectionHasAllMembers
      def self.call(...)
        new(...).call
      end

      attr_reader :collection
      attr_reader :document_ids
      attr_reader :deserializer
      attr_reader :prefix

      delegate :id_param, :resource_class, to: :deserializer

      def initialize(collection, document_ids, deserializer, prefix: '/data')
        @collection = collection
        @document_ids = document_ids
        @deserializer = deserializer
        @prefix = prefix
      end

      def call
        if collection.size != document_ids.size
          collection_ids = deserializer.format_collection_ids(collection)
          raise build_missing_resources_error(collection_ids)
        end
      end

      def resource_type
        deserializer.type
      end

      private

      def build_missing_resources_error(collection_ids)
        payload = document_ids.each_with_index.map do |resource_id, index|
          build_missing_resource_payload(collection_ids, resource_id, index)
        end.reject(&:nil?)

        missing_values = document_ids.reject { |value| collection_ids.include?(value.to_s) }
        message = "Couldn't find #{resource_class} items with "\
                  "#{id_param} in #{missing_values.inspect}"
        Exceptions::MissingResource.new(message, payload)
      end

      def build_missing_resource_payload(collection_ids, resource_id, index)
        unless collection_ids.include?(resource_id)
          ExceptionPayload.new(
            pointer: "#{prefix}/#{index}",
            detail: missing_resource_message(resource_id)
          )
        end
      end

      def missing_resource_message(resource_id)
        I18n.t(
          :missing_resource,
          resource: resource_type,
          resource_id: resource_id,
          scope: 'fun_with_json_api.find_collection_from_document'
        )
      end
    end
  end
end
