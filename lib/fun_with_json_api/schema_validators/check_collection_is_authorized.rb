require 'fun_with_json_api/exception'

module FunWithJsonApi
  module SchemaValidators
    class CheckCollectionIsAuthorised
      def self.call(...)
        new(...).call
      end

      attr_reader :collection
      attr_reader :collection_ids
      attr_reader :deserializer
      attr_reader :prefix

      delegate :resource_class,
               to: :deserializer

      def initialize(collection, collection_ids, deserializer, prefix: '/data')
        @collection = collection
        @collection_ids = collection_ids
        @deserializer = deserializer
        @prefix = prefix
      end

      def call
        payload = collection.each_with_index.map do |resource, index|
          build_unauthorized_resource_payload(resource, index)
        end.reject(&:nil?)

        return if payload.empty?

        raise Exceptions::UnauthorizedResource.new(
          "resource_authorizer method for one or more '#{deserializer.type}' items returned false",
          payload
        )
      end

      def resource_type
        deserializer.type
      end

      private

      def build_unauthorized_resource_payload(resource, index)
        unless deserializer.resource_authorizer.call(resource)
          ExceptionPayload.new(
            pointer: "#{prefix}/#{index}",
            detail: unauthorized_resource_message(collection_ids[index])
          )
        end
      end

      def unauthorized_resource_message(resource_id)
        I18n.t(
          :unauthorized_resource,
          resource: resource_type,
          resource_id: resource_id,
          scope: 'fun_with_json_api.find_collection_from_document'
        )
      end
    end
  end
end
