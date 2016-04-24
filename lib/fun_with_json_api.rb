require 'fun_with_json_api/attribute'
require 'fun_with_json_api/exception'

require 'fun_with_json_api/json_api_resource'
require 'fun_with_json_api/active_model_resource'

require 'fun_with_json_api/active_model_serializers/resource_deserializer'
require 'fun_with_json_api/active_model_serializers/serializer_generator'

require 'fun_with_json_api/configuration'
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

  def build_json_api_resource(resource_class, resource_options)
    if resource_class.is_a? Class
      resource_class.create(resource_options)
    else
      resource_class
    end
  end

  def deserialize(document, json_api_resource_class, resource_or_nil = nil, options = {})
    FunWithJsonApi::ActiveModelSerializers::ResourceDeserializer.new(
      json_api_resource_class, options
    ).deserialize(document, resource_or_nil)
  end

  def deserialize_resource(document, json_api_resource_class, resource, options = {})
    raise ArgumentError, 'resource cannot be nil' if resource.nil?
    deserialize(document, json_api_resource_class, resource, options)
  end

  def sanitize_document(document)
    document = document.dup.permit!.to_h if document.is_a?(ActionController::Parameters)
    document.deep_stringify_keys
  end

  def find_resource(document, json_api_resource_class, options = {})
    # Prepare the json_api_resource for loading a resource
    json_api_resource = json_api_resource_class.create(options.merge(attributes: [], relationships: []))

    # Load the resource from the document id
    FunWithJsonApi::FindResourceFromDocument.find(document, json_api_resource)
  end

  def find_collection(document, json_api_resource_class, options = {})
    # Prepare the json_api_resource for loading a resource
    json_api_resource = json_api_resource_class.create(options.merge(attributes: [], relationships: []))

    # Load the collection from the document
    FunWithJsonApi::FindCollectionFromDocument.find(document, json_api_resource)
  end
end

require 'fun_with_json_api/railtie' if defined?(Rails)
