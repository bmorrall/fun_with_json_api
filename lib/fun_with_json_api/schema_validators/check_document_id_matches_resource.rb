module FunWithJsonApi
  module SchemaValidators
    class CheckDocumentIdMatchesResource < Base
      # Checks if the document id matches the resource being updated, or if it can be assigned
      def call
        if resource.try(:persisted?)
          # Ensure correct update document is being sent
          check_resource_id_is_a_string
          check_resource_id_matches_document_id
        elsif document_id
          # Ensure correct create document is being sent
          check_resource_id_is_a_string
          check_resource_id_can_be_client_generated
          check_resource_id_has_not_already_been_used
        end
      end

      def check_resource_id_is_a_string
        unless document_id.is_a?(String)
          payload = ExceptionPayload.new(
            detail: document_id_is_not_a_string_message,
            pointer: '/data/id'
          )
          message = "document id is not a string: #{document_id.class.name}"
          raise Exceptions::InvalidDocumentIdentifier.new(message, payload)
        end
      end

      def check_resource_id_matches_document_id
        if document_id != resource_id
          message = "resource id '#{resource_id}' does not match the expected id for"\
                    " '#{resource_type}': '#{document_id}'"
          payload = ExceptionPayload.new(
            detail: document_id_does_not_match_resource_message
          )
          raise Exceptions::InvalidDocumentIdentifier.new(message, payload)
        end
      end

      def check_resource_id_can_be_client_generated
        # Ensure id has been provided as an attribute
        if json_api_resource.attributes.none? { |attribute| attribute.name == :id }
          json_api_resource_name = json_api_resource.class.name || 'JsonApiResource'
          message = "id parameter for '#{resource_type}' cannot be set"\
                    " as it has not been defined as a #{json_api_resource_name} attribute"
          payload = ExceptionPayload.new(
            detail: resource_id_can_not_be_client_generated_message
          )
          raise Exceptions::IllegalClientGeneratedIdentifier.new(message, payload)
        end
      end

      def check_resource_id_has_not_already_been_used
        if (existing = json_api_resource.load_resource_from_id_value(document_id))
          json_api_resource_class = json_api_resource.class.name || 'JsonApiResource'
          message = "#{json_api_resource_class}#load_resource_from_id_value for '#{resource_type}' has"\
                    ' found a existing resource matching document id'\
                    ": #{existing.class.name}##{existing.id}"
          payload = ExceptionPayload.new(
            detail: resource_id_has_already_been_used_message
          )
          raise Exceptions::InvalidClientGeneratedIdentifier.new(message, payload)
        end
      end

      private

      def document_id_is_not_a_string_message
        I18n.t(
          :document_id_is_not_a_string_message,
          scope: 'fun_with_json_api.schema_validators'
        )
      end

      def document_id_does_not_match_resource_message
        I18n.t(
          :document_id_does_not_match_resource,
          expected: resource_id,
          scope: 'fun_with_json_api.schema_validators'
        )
      end

      def resource_id_can_not_be_client_generated_message
        I18n.t(
          :resource_id_can_not_be_client_generated,
          resource: resource_type,
          scope: 'fun_with_json_api.schema_validators'
        )
      end

      def resource_id_has_already_been_used_message
        I18n.t(
          :resource_id_has_already_been_assigned,
          id: document_id,
          resource: resource_type,
          scope: 'fun_with_json_api.schema_validators'
        )
      end
    end
  end
end
