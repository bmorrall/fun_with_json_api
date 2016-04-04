require 'active_support/inflector'
require 'fun_with_json_api/attribute'
require 'fun_with_json_api/deserializer_class_methods'

module FunWithJsonApi
  class Deserializer
    extend FunWithJsonApi::DeserializerClassMethods

    # Fake resource_authorizer that always returns 'authorised'
    class ResourceAuthorizerDummy
      def call(_)
        true
      end
    end

    # Creates a new instance of a
    def self.create(options = {})
      new(options)
    end

    # Use DeserializerClass.create to build new instances
    private_class_method :new

    attr_reader :id_param
    attr_reader :type

    def initialize(options = {})
      @id_param = options.fetch(:id_param) { self.class.id_param }
      @type = options.fetch(:type) { self.class.type }
      @resource_class = options[:resource_class]
      @resource_collection = options[:resource_collection] if @type
      @resource_authorizer = options[:resource_authorizer]
      load_attributes_from_options(options)
      load_relationships_from_options(options)
    end

    # Loads a collection of of `resource_class` instances with `id_param` matching `id_values`
    def load_collection_from_id_values(id_values)
      resource_collection.where(id_param => id_values)
    end

    def format_resource_id(resource)
      resource.public_send(id_param).to_s
    end

    def format_collection_ids(collection)
      collection.map { |resource| format_resource_id(resource) }
    end

    # Loads a single instance of `resource_class` with a `id_param` matching `id_value`
    def load_resource_from_id_value(id_value)
      resource_collection.find_by(id_param => id_value)
    end

    def resource_is_soft_deleted?(id_value)
      if resource_collection.respond_to?(:only_deleted)
        resource_collection.only_deleted.where(id_param => id_value).any?
      else
        false
      end
    end

    # Takes a parsed params hash from ActiveModelSerializers::Deserialization and sanitizes values
    def sanitize_params(params)
      Hash[
        serialize_attribute_values(attributes, params) +
        serialize_attribute_values(relationships, params)
      ]
    end

    def resource_class
      @resource_class ||= self.class.resource_class
    end

    def resource_collection
      @resource_collection ||= resource_class
    end

    def resource_authorizer
      @resource_authorizer ||= ResourceAuthorizerDummy.new
    end

    def attributes
      attribute_lookup.values
    end

    def relationships
      relationship_lookup.values
    end

    def attribute_for(attribute_name)
      attribute_lookup.fetch(attribute_name)
    end

    def relationship_for(resource_name)
      relationship_lookup.fetch(resource_name)
    end

    private

    attr_reader :attribute_lookup
    attr_reader :relationship_lookup

    def load_attributes_from_options(options)
      attributes = filter_attributes_by_name(options[:attributes], self.class.attribute_names)
      @attribute_lookup = {}
      self.class.build_attributes(attributes).each do |attribute|
        @attribute_lookup[attribute.name] = attribute
      end
    end

    def load_relationships_from_options(options = {})
      options_config = {}

      # Filter resources and build an options hash for each
      filter_relationships_by_name(
        options[:relationships], self.class.relationship_names
      ).each do |relationship|
        options_config[relationship] = options.fetch(relationship, {})
      end

      # Build the relationships and store them into a lookup hash
      @relationship_lookup = {}
      self.class.build_relationships(options_config).each do |relationship|
        @relationship_lookup[relationship.name] = relationship
      end
    end

    def filter_attributes_by_name(attribute_names, attributes)
      if attribute_names
        attributes.keep_if { |attribute| attribute_names.include?(attribute) }
      else
        attributes
      end
    end

    def filter_relationships_by_name(relationship_names, relationships)
      if relationship_names
        relationships.keep_if { |relationship| relationship_names.include?(relationship) }
      else
        relationships
      end
    end

    # Calls <attribute.as> on the current instance, override the #<as> method to change loading
    def serialize_attribute_values(attributes, params)
      attributes.select { |attribute| params.key?(attribute.param_value) }
                .map { |attribute| serialize_attribute(attribute, params) }
    end

    # Calls <attribute.as> on the current instance, override the #<as> method to change loading
    def serialize_attribute(attribute, params)
      raw_value = params.fetch(attribute.param_value)
      [attribute.param_value, public_send(attribute.sanitize_attribute_method, raw_value)]
    end
  end
end
