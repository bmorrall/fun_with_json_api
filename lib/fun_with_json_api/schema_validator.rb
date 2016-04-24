require 'fun_with_json_api/exception'

module FunWithJsonApi
  class SchemaValidator
    def self.check(*args)
      new(*args).check
    end

    private_class_method :new

    attr_reader :document
    attr_reader :json_api_resource
    attr_reader :resource

    def initialize(json_api_resource, document, resource)
      @document = FunWithJsonApi.sanitize_document(document)
      @json_api_resource = json_api_resource
      @resource = resource
    end

    def check
      [
        FunWithJsonApi::SchemaValidators::CheckDocumentTypeMatchesResource,
        FunWithJsonApi::SchemaValidators::CheckDocumentIdMatchesResource,
        FunWithJsonApi::SchemaValidators::CheckAttributeNames,
        FunWithJsonApi::SchemaValidators::CheckRelationships
      ].each { |validator| validator.call(json_api_resource, document, resource) }
    end
  end
end

# Load known Schema Validators
require 'fun_with_json_api/schema_validators/base'
Dir["#{File.dirname(__FILE__)}/schema_validators/**/check_*.rb"].each { |f| require f }
