require 'fun_with_json_api/exception'
require 'fun_with_json_api/attribute'

require 'fun_with_json_api/active_model_serializers/serializer_generator'

require 'fun_with_json_api/configuration'
require 'fun_with_json_api/pre_deserializer'
require 'fun_with_json_api/deserializer'
require 'fun_with_json_api/schema_validator'
require 'fun_with_json_api/find_collection_from_document'
require 'fun_with_json_api/find_resource_from_document'
require 'fun_with_json_api/collection_manager'

# Makes working with JSON:API fun!
module FunWithJsonApi
  MEDIA_TYPE = 'application/vnd.api+json'.freeze

  module_function

  attr_writer :configuration

  def configuration
    @configuration ||= Configuration.new
  end

  def configure
    yield(configuration)
  end

  def deserialize(document, deserializer_class, resource = nil, options = {})
    # Prepare the deserializer and the expected config
    deserializer = deserializer_class.create(options)

    # Run through initial document structure validation and deserialization
    unfiltered = FunWithJsonApi::PreDeserializer.parse(document, deserializer)

    # Check the document matches up with expected resource parameters
    FunWithJsonApi::SchemaValidator.check(document, deserializer, resource)

    # Ensure document matches schema, and sanitize values
    deserializer.sanitize_params(unfiltered)
  end

  def deserialize_resource(document, deserializer_class, resource, options = {})
    raise ArgumentError, 'resource cannot be nil' if resource.nil?
    deserialize(document, deserializer_class, resource, options)
  end

  def sanitize_document(document)
    document = document.dup.permit!.to_h if document.is_a?(ActionController::Parameters)
    document.deep_stringify_keys
  end

  def find_resource(document, deserializer_class, options = {})
    # Prepare the deserializer for loading a resource
    deserializer = deserializer_class.create(options.merge(attributes: [], relationships: []))

    # Load the resource from the document id
    FunWithJsonApi::FindResourceFromDocument.find(document, deserializer)
  end

  def find_collection(document, deserializer_class, options = {})
    # Prepare the deserializer for loading a resource
    deserializer = deserializer_class.create(options.merge(attributes: [], relationships: []))

    # Load the collection from the document
    FunWithJsonApi::FindCollectionFromDocument.find(document, deserializer)
  end
end

require 'fun_with_json_api/railtie' if defined?(Rails)
