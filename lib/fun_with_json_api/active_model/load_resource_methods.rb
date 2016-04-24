module FunWithJsonApi
  module ActiveModel
    module LoadResourceMethods
      def encode_resource_id(resource)
        resource.public_send(id_param).to_s
      end

      def encode_collection_ids(collection)
        collection.map { |resource| encode_resource_id(resource) }
      end
    end
  end
end
