module FunWithJsonApi
  class FindResourceFromDocument
    def self.find(*args)
      new(*args).find
    end

    private_class_method :new

    attr_reader :api_document
    attr_reader :deserializer

    def initialize(api_document, deserializer)
      @api_document = api_document.deep_stringify_keys
      @deserializer = deserializer
    end

    def find
      raise build_invalid_document_error unless document_is_valid?

      # Resource is being set to nil/null
      return nil if document_is_null_resource?

      # Ensure the document matches the expected resource
      raise build_invalid_document_type_error unless document_matches_resource_type?

      # Load resource from id value
      deserializer.load_resource_from_id_value(document_id).tap do |resource|
        raise build_missing_resource_error if resource.nil?
      end
    end

    def document_id
      @document_id ||= api_document['data']['id']
    end

    def document_type
      @document_type ||= api_document['data']['type']
    end

    def resource_type
      @resource_type ||= deserializer.type
    end

    def document_is_valid?
      api_document.key?('data') && (
        api_document['data'].is_a?(Hash) || document_is_null_resource?
      )
    end

    def document_is_null_resource?
      api_document['data'].nil?
    end

    def document_matches_resource_type?
      resource_type == document_type
    end

    private

    def build_invalid_document_error
      payload = ExceptionPayload.new
      payload.pointer = '/data'
      payload.detail = document_is_invalid_message
      Exceptions::InvalidDocument.new(
        "Expected root data element with hash or null: #{api_document.inspect}",
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
      deserializer_name = deserializer.class.name || 'Deserializer'
      message = "#{deserializer_name} was unable to find resource by '#{deserializer.id_param}'"\
                ": '#{document_id}'"
      payload = ExceptionPayload.new
      payload.pointer = '/data/id'
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