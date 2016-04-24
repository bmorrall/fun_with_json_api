require 'fun_with_json_api/schema_validators/check_collection_is_authorized'
require 'fun_with_json_api/schema_validators/check_collection_has_all_members'

module FunWithJsonApi
  class FindCollectionFromDocument
    def self.find(*args)
      new(*args).find
    end

    private_class_method :new

    attr_reader :document
    attr_reader :json_api_resource
    delegate :id_param, :id_param, :resource_class, to: :json_api_resource

    def initialize(document, json_api_resource)
      @document = FunWithJsonApi.sanitize_document(document)
      @json_api_resource = json_api_resource
    end

    def find
      raise build_invalid_document_error unless document_is_valid_collection?

      # Skip the checks, no point running through them for an empty array
      return [] if document_ids.empty?

      # Ensure the document matches the expected resource
      check_document_types_match_json_api_resource!

      # Load resource from id value
      json_api_resource.load_collection_from_id_values(document_ids).tap do |collection|
        check_collection_contains_all_requested_resources!(collection)
        check_collection_is_authorised!(collection)
      end
    end

    def document_ids
      @document_id ||= document['data'].map { |item| item['id'] }
    end

    def document_types
      @document_type ||= document['data'].map { |item| item['type'] }.uniq
    end

    def resource_type
      @resource_type ||= json_api_resource.type
    end

    def document_is_valid_collection?
      document.key?('data') && document['data'].is_a?(Array)
    end

    private

    def check_collection_contains_all_requested_resources!(collection)
      SchemaValidators::CheckCollectionHasAllMembers.call(collection, document_ids, json_api_resource)
    end

    def check_collection_is_authorised!(collection)
      SchemaValidators::CheckCollectionIsAuthorised.call(collection, document_ids, json_api_resource)
    end

    def check_document_types_match_json_api_resource!
      invalid_document_types = document_types.reject { |type| type == resource_type }
      raise build_invalid_document_types_error if invalid_document_types.any?
    end

    def build_invalid_document_error
      payload = ExceptionPayload.new
      payload.pointer = '/data'
      payload.detail = 'Expected data to be an Array of resources'
      Exceptions::InvalidDocument.new(
        "Expected root data element with an Array: #{document.inspect}",
        payload
      )
    end

    def build_invalid_document_types_error
      message = 'Expected type for each item to match expected resource type'\
                ": '#{resource_type}'"
      payload = document['data'].each_with_index.map do |data, index|
        next if data['type'] == resource_type
        ExceptionPayload.new(
          pointer: "/data/#{index}/type",
          detail: document_type_does_not_match_endpoint_message(data['type'])
        )
      end.reject(&:nil?)
      Exceptions::InvalidDocumentType.new(message, payload)
    end

    def document_type_does_not_match_endpoint_message(type)
      I18n.t(
        :invalid_document_type,
        type: type,
        resource: resource_type,
        scope: 'fun_with_json_api.find_collection_from_document'
      )
    end
  end
end
