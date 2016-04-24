module FunWithJsonApi
  class FindResourceFromDocument
    def self.find(*args)
      new(*args).find
    end

    private_class_method :new

    attr_reader :document
    attr_reader :json_api_resource

    def initialize(document, json_api_resource)
      @document = FunWithJsonApi.sanitize_document(document)
      @json_api_resource = json_api_resource
    end

    def find
      raise build_invalid_document_error unless document_is_valid?

      # Resource is being set to nil/null
      return nil if document_is_null_resource?

      # Ensure the document matches the expected resource
      raise build_invalid_document_type_error unless document_matches_resource_type?

      # Load resource from id value
      load_resource_and_check!
    end

    def document_id
      @document_id ||= document['data']['id']
    end

    def document_type
      @document_type ||= document['data']['type']
    end

    def resource_type
      @resource_type ||= json_api_resource.type
    end

    def document_is_valid?
      document.key?('data') && (
        document['data'].is_a?(Hash) || document_is_null_resource?
      )
    end

    def document_is_null_resource?
      document['data'].nil?
    end

    def document_matches_resource_type?
      resource_type == document_type
    end

    private

    def load_resource_and_check!
      json_api_resource.load_resource_from_id_value(document_id).tap do |resource|
        raise build_missing_resource_error if resource.nil?
        FunWithJsonApi::SchemaValidators::CheckResourceIsAuthorised.call(
          resource, document_id, json_api_resource
        )
      end
    end

    def build_invalid_document_error
      payload = ExceptionPayload.new
      payload.pointer = '/data'
      payload.detail = document_is_invalid_message
      Exceptions::InvalidDocument.new(
        "Expected root data element with hash or null: #{document.inspect}",
        payload
      )
    end

    def build_invalid_document_type_error
      message = "'#{document_type}' did not match expected resource type: '#{resource_type}'"
      payload = ExceptionPayload.new(
        detail: document_type_does_not_match_endpoint_message
      )
      Exceptions::InvalidDocumentType.new(message, payload)
    end

    def build_missing_resource_error
      json_api_resource_name = json_api_resource.class.name || 'JsonApiResource'
      message = "#{json_api_resource_name} was unable to find resource by '#{json_api_resource.id_param}'"\
                ": '#{document_id}'"
      payload = ExceptionPayload.new
      payload.pointer = '/data'
      payload.detail = missing_resource_message
      Exceptions::MissingResource.new(message, payload)
    end

    def document_is_invalid_message
      I18n.t(
        :invalid_document,
        scope: 'fun_with_json_api.find_resource_from_document'
      )
    end

    def document_type_does_not_match_endpoint_message
      I18n.t(
        :invalid_document_type,
        resource: resource_type,
        scope: 'fun_with_json_api.find_resource_from_document'
      )
    end

    def missing_resource_message
      I18n.t(
        :missing_resource,
        resource: resource_type,
        resource_id: document_id,
        scope: 'fun_with_json_api.find_resource_from_document'
      )
    end
  end
end
