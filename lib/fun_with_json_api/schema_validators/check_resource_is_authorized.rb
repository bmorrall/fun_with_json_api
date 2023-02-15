require 'fun_with_json_api/exception'

module FunWithJsonApi
  module SchemaValidators
    class CheckResourceIsAuthorised
      def self.call(...)
        new(...).call
      end

      attr_reader :resource
      attr_reader :resource_id
      attr_reader :deserializer
      attr_reader :resource_pointer

      def initialize(resource, resource_id, deserializer, resource_pointer: '/data')
        @resource = resource
        @resource_id = resource_id
        @deserializer = deserializer
        @resource_pointer = resource_pointer
      end

      def call
        unless deserializer.resource_authorizer.call(resource)
          raise Exceptions::UnauthorizedResource.new(
            "resource_authorizer method for '#{deserializer.type}' returned a false value",
            ExceptionPayload.new(
              pointer: resource_pointer,
              detail: unauthorized_resource_message
            )
          )
        end
      end

      def resource_type
        deserializer.type
      end

      private

      def unauthorized_resource_message
        I18n.t(
          :unauthorized_resource,
          resource: resource_type,
          resource_id: resource_id,
          scope: 'fun_with_json_api.find_resource_from_document'
        )
      end
    end
  end
end
