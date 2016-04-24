require 'active_support/inflector'
require 'fun_with_json_api/json_api_resource'
require 'fun_with_json_api/active_model/load_resource_methods'

module FunWithJsonApi
  # Defines a JsonApiResource with a ActiveModel::Base resource
  class ActiveModelResource < JsonApiResource
    include FunWithJsonApi::ActiveModel::LoadResourceMethods

    class << self
      def resource_class(resource_class = nil)
        if resource_class
          lock.synchronize do
            @resource_class = resource_class
          end
        end
        @resource_class || type.singularize.classify.constantize
      end

      private

      def lock
        @lock ||= Mutex.new
      end
    end

    def initialize(options = {})
      @resource_class = options[:resource_class]
      @resource_collection = options[:resource_collection]
      super
    end

    # Loads a collection of of `resource_class` instances with `id_param` matching `id_values`
    def load_collection_from_id_values(id_values)
      resource_collection.where(id_param => id_values)
    end

    # Loads a single instance of `resource_class` with a `id_param` matching `id_value`
    def load_resource_from_id_value(id_value)
      resource_collection.find_by(id_param => id_value)
    end

    def encode_resource_id(resource)
      resource.public_send(id_param).to_s
    end

    def encode_collection_ids(collection)
      collection.map { |resource| encode_resource_id(resource) }
    end

    def resource_class
      @resource_class ||= self.class.resource_class
    end

    def resource_collection
      @resource_collection ||= resource_class
    end
  end
end
