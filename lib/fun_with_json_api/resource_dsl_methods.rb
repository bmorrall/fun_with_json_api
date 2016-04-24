require 'fun_with_json_api/attribute'

module FunWithJsonApi
  # Provides a basic DSL for defining a FunWithJsonApi::ActiveModelResource
  module ResourceDSLMethods
    def id_param(id_param = nil, format: false)
      lock.synchronize do
        @id_param = id_param.to_sym if id_param
      end
      (@id_param || :id).tap do |param|
        if format
          attribute(:id, as: param, format: format) # Create a new id attribute
        end
      end
    end

    def type(type = nil)
      lock.synchronize do
        @type = type if type
      end
      @type || type_from_class_name
    end

    # Attributes

    def attribute(name, options = {})
      lock.synchronize do
        Attribute.create(name, options).tap do |attribute|
          add_convert_attribute_methods(attribute)
          attributes << attribute
        end
      end
    end

    def attribute_names
      lock.synchronize { attributes.map(&:name) }
    end

    def build_attributes(names)
      lock.synchronize do
        names.map do |name|
          attribute = attributes.detect { |rel| rel.name == name }
          attribute.class.create(attribute.name, attribute.options)
        end
      end
    end

    # Relationships

    def belongs_to(name, json_api_resource_class_or_callable, options = {})
      lock.synchronize do
        Attributes::Relationship.create(
          name,
          json_api_resource_class_or_callable,
          options
        ).tap do |relationship|
          add_convert_relationship_methods(relationship)
          relationships << relationship
        end
      end
    end

    # rubocop:disable Style/PredicateName

    def has_many(name, json_api_resource_class_or_callable, options = {})
      lock.synchronize do
        Attributes::RelationshipCollection.create(
          name,
          json_api_resource_class_or_callable,
          options
        ).tap do |relationship|
          add_convert_relationship_methods(relationship)
          relationships << relationship
        end
      end
    end

    # rubocop:enable Style/PredicateName

    def relationship_names
      lock.synchronize { relationships.map(&:name) }
    end

    def build_relationships(options)
      lock.synchronize do
        options.map do |name, relationship_options|
          relationship = relationships.detect { |rel| rel.name == name }
          relationship.class.create(
            relationship.name,
            relationship.json_api_resource_class,
            relationship_options.reverse_merge(relationship.options)
          )
        end
      end
    end

    private

    def lock
      @lock ||= Mutex.new
    end

    def attributes
      @attributes ||= []
    end

    def relationships
      @relationships ||= []
    end

    def add_convert_attribute_methods(attribute)
      define_method(attribute.decode_attribute_method) do |param_value|
        attribute_for(attribute.name).decode(param_value)
      end
      if attribute.name != :id
        define_method(attribute.encode_attribute_method) do |resource|
          attribute_for(attribute.name).encode(resource)
        end
      end
    end

    def add_convert_relationship_methods(relationship)
      define_method(relationship.decode_attribute_method) do |param_value|
        relationship_for(relationship.name).decode(param_value)
      end
      define_method(relationship.encode_attribute_method) do |resource|
        relationship_for(relationship.name).encode(resource)
      end
    end

    def type_from_class_name
      if name.nil?
        Rails.logger.warn 'Unable to determine type for anonymous JsonApiResource'
        return nil
      end

      resource_class_name = name.demodulize.sub(/JsonApiResource\z/, '').underscore
      if ::ActiveModelSerializers.config.jsonapi_resource_type == :singular
        resource_class_name.singularize
      else
        resource_class_name.pluralize
      end
    end
  end
end
