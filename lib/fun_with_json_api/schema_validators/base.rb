module FunWithJsonApi
  module SchemaValidators
    # Requires base interface for a deserialize
    class Base
      def self.call(*args)
        new(*args).call
      end

      private_class_method :new

      attr_reader :json_api_resource
      attr_reader :document
      attr_reader :resource

      def initialize(json_api_resource, document, resource)
        @json_api_resource = json_api_resource
        @document = document
        @resource = resource
      end

      def document_id
        @document_id ||= document['data']['id']
      end

      def document_type
        @document_type ||= document['data']['type']
      end

      def resource_id
        @resource_id ||= json_api_resource.encode_id(resource)
      end

      def resource_type
        @resource_type ||= json_api_resource.type
      end
    end
  end
end
