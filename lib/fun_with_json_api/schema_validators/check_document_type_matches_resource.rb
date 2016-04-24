module FunWithJsonApi
  module SchemaValidators
    class CheckDocumentTypeMatchesResource < Base
      # Ensures the document type matches the expected resource
      def call
        if document_type != resource_type
          message = "'#{document_type}' does not match the expected resource"\
                    ": #{resource_type}"
          payload = ExceptionPayload.new(
            detail: document_type_does_not_match_endpoint_message
          )
          raise Exceptions::InvalidDocumentType.new(message, payload)
        end
      end

      private

      def document_type_does_not_match_endpoint_message
        I18n.t(
          :document_type_does_not_match_endpoint,
          expected: resource_type,
          scope: 'fun_with_json_api.schema_validators'
        )
      end
    end
  end
end
