module FunWithJsonApi
  module SchemaValidators
    # Ensures all provided relationship names are known
    class CheckRelationshipNames
      def self.call(*args)
        new(*args).call
      end

      attr_reader :document
      attr_reader :json_api_resource
      attr_reader :relationship_keys

      def initialize(document, json_api_resource, relationship_keys)
        @document = document
        @json_api_resource = json_api_resource
        @relationship_keys = relationship_keys
      end

      def call
        unknown = relationship_keys.reject { |rel| resource_relationships.include?(rel) }
        return if unknown.empty?

        unauthorised_relationships = unknown.select do |relationship|
          known_relationships.include?(relationship)
        end
        if unauthorised_relationships.any?
          raise build_unauthorized_relationship_error(unauthorised_relationships)
        else
          raise build_unknown_relationship_error(unknown)
        end
      end

      protected

      def resource_relationships
        @resource_relationships ||= json_api_resource.relationships.map(&:name).map(&:to_s)
      end

      def known_relationships
        @known_relationships ||= json_api_resource.class.relationship_names.map(&:to_s)
      end

      private

      def build_unauthorized_relationship_error(unauthorised_relationships)
        payload = unauthorised_relationships.map do |relationship|
          build_unauthorized_relationship_payload(relationship)
        end
        message = 'Unauthorized relationships were provided by endpoint'
        FunWithJsonApi::Exceptions::UnauthorizedRelationship.new(message, payload)
      end

      def build_unknown_relationship_error(unknown_relationships)
        payload = unknown_relationships.map do |relationship|
          build_unknown_relationship_payload(relationship)
        end
        message = 'Unknown relationships were provided by endpoint'
        FunWithJsonApi::Exceptions::UnknownRelationship.new(message, payload)
      end

      # Relationship is known, but not supported by this request
      def build_unauthorized_relationship_payload(relationship)
        ExceptionPayload.new(
          detail: unauthorized_relationship_error(relationship),
          pointer: "/data/relationships/#{relationship}"
        )
      end

      # Relationship is completely unknown, can cannot be assigned to this resource type (ever!)
      def build_unknown_relationship_payload(relationship)
        ExceptionPayload.new(
          detail: unknown_relationship_error(relationship),
          pointer: "/data/relationships/#{relationship}"
        )
      end

      def unknown_relationship_error(relationship)
        I18n.t(
          :unknown_relationship_for_resource,
          relationship: relationship,
          resource: json_api_resource.type,
          scope: 'fun_with_json_api.schema_validators'
        )
      end

      def unauthorized_relationship_error(relationship)
        I18n.t(
          :unauthorized_relationship,
          relationship: relationship,
          resource: json_api_resource.type,
          scope: 'fun_with_json_api.schema_validators'
        )
      end
    end
  end
end
