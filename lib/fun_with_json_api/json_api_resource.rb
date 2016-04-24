require 'fun_with_json_api/attribute'
require 'fun_with_json_api/resource_dsl_methods'

module FunWithJsonApi
  class JsonApiResource
    extend FunWithJsonApi::ResourceDSLMethods

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

    # Use JsonApiResource<Class>.create to build new instances
    private_class_method :new

    attr_reader :id_param
    attr_reader :type

    def initialize(options = {})
      @id_param = options.fetch(:id_param) { self.class.id_param }
      @type = options.fetch(:type) { self.class.type }
      @resource_authorizer = options[:resource_authorizer]
      load_attributes_from_options(options)
      load_relationships_from_options(options)
    end

    def encode_id(resource)
      id_attribute.encode(resource).to_s
    end

    def id_attribute
      @id_attribute ||= attributes.detect do |attribute|
        attribute.name == :id
      end || Attribute.create(:id, as: id_param)
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
  end
end
