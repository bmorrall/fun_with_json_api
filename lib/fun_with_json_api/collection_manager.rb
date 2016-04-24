require 'fun_with_json_api/exception'

module FunWithJsonApi
  # Abstract Handles updating a collection relationship.
  # Override the `insert`, `remove` and `replace` methods, or provide a block that perfoms the
  # desired action on the collection.
  class CollectionManager
    attr_reader :parent_resource
    attr_reader :json_api_resource

    def initialize(parent_resource, json_api_resource_class, json_api_resource_options)
      @parent_resource = parent_resource
      @json_api_resource = json_api_resource_class.create(json_api_resource_options)
    end

    # Inserts a single record into a collection
    # Must return true for a successful update, or return false for any failures
    def insert_record(_record)
      raise build_relationship_not_supported_exception(
        "Override #{self.class.name}#insert_record",
        insert_not_supported_message
      )
    end

    # Removes a single record into a collection
    # Must return true for a successful update, or return false for any failures
    def remove_record(_record)
      raise build_relationship_not_supported_exception(
        "Override #{self.class.name}#remove_record",
        remove_not_supported_message
      )
    end

    # Inserts all records from a collection into the parent resource
    #
    # Will attempt to call `insert_record` for each item in the `collection`.
    # If false is received for any `insert_record` call, an exception with a payload will be raised
    # after all items have been iterated through
    #
    # You need to reverse all changes made in the event of an exception,
    # wrapping an an ActiveRecord::Base.transaction block will usually work
    #
    # Action is not supported unless `insert_records` or the `insert_record` method is overridden
    def insert_records(collection, failure_message_or_callable = nil)
      update_collection_items(collection, failure_message_or_callable) do |record|
        insert_record(record)
      end
    end

    # Removes all records from a collection into the parent resource
    #
    # Will attempt to call `remove_record` for each item in the `collection`.
    # If false is received for any `remove_record` call, an exception with a payload will be raised
    # after all items have been iterated through
    #
    # You need to reverse all changes made in the event of an exception,
    # wrapping an an ActiveRecord::Base.transaction block will usually work
    #
    # Action is not supported unless `remove_records` or the `remove_record` method is overridden
    def remove_records(collection, failure_message_or_callable = nil)
      update_collection_items(collection, failure_message_or_callable) do |record|
        remove_record(record)
      end
    end

    # Replaces all records
    def replace_all_records(_collection)
      # Action is not supported unless overridden
      raise build_relationship_not_supported_exception(
        "Override #{self.class.name}#replace_all_records to implement replace all",
        replace_all_not_supported_message
      )
    end

    def failure_message_for_resource(resource, failure_message_or_callable)
      resource_id = json_api_resource.encode_resource_id(resource)
      failure_message = failure_message_or_callable
      if failure_message.respond_to?(:call)
        failure_message = failure_message.call(resource_id)
      end
      failure_message || default_invalid_resource_message(resource_id)
    end

    protected

    def insert_not_supported_message
      I18n.t(
        'insert_not_supported',
        resource: json_api_resource.type,
        scope: 'fun_with_json_api.collection_manager'
      )
    end

    def remove_not_supported_message
      I18n.t(
        'remove_not_supported',
        resource: json_api_resource.type,
        scope: 'fun_with_json_api.collection_manager'
      )
    end

    def replace_all_not_supported_message
      I18n.t(
        'replace_all_not_supported',
        resource: json_api_resource.type,
        scope: 'fun_with_json_api.collection_manager'
      )
    end

    def default_invalid_resource_message(resource_id)
      I18n.t(
        'invalid_resource',
        resource: json_api_resource.type,
        resource_id: resource_id,
        scope: 'fun_with_json_api.collection_manager'
      )
    end

    def update_collection_items(collection, failure_message_or_callable = nil)
      failed_resources_hash = {}
      collection.each_with_index.map do |resource, index|
        failed_resources_hash[index] = resource unless yield(resource)
      end.reject(&:nil?)
      if failed_resources_hash.any?
        raise_invalid_resource_exception(failed_resources_hash, failure_message_or_callable)
      end
    end

    private

    def build_relationship_not_supported_exception(debug_message, exception_message)
      Exceptions::RelationshipMethodNotSupported.new(
        debug_message, ExceptionPayload.new(detail: exception_message)
      )
    end

    def raise_invalid_resource_exception(failed_resources_hash, failure_message_or_callable)
      raise Exceptions::InvalidResource.new(
        'Unable to update relationship due to errors with collection',
        build_invalid_resource_exception_payload(failed_resources_hash, failure_message_or_callable)
      )
    end

    def build_invalid_resource_exception_payload(failed_resources_hash, failure_message_or_callable)
      failed_resources_hash.map do |index, resource|
        failure_message = failure_message_for_resource(resource, failure_message_or_callable)
        ExceptionPayload.new(detail: failure_message, pointer: "/data/#{index}")
      end
    end
  end
end
