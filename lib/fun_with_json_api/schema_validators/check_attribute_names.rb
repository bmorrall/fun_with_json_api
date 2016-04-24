module FunWithJsonApi
  module SchemaValidators
    class CheckAttributeNames < Base
      def call
        attributes = document['data'].fetch('attributes', {}).keys

        unknown = attributes.reject { |attribute| resource_attributes.include?(attribute) }
        check_attribute_names(unknown) if unknown.any?

        true
      end

      def resource_attributes
        @resource_attributes ||= json_api_resource.attributes.map(&:name).map(&:to_s)
      end

      def known_attributes
        @known_attributes ||= json_api_resource.class.attribute_names.map(&:to_s)
      end

      private

      def check_attribute_names(unknown)
        unauthorised_attributes = unknown.select do |attribute|
          known_attributes.include?(attribute)
        end
        if unauthorised_attributes.any?
          raise build_forbidden_attribute_error(unauthorised_attributes)
        else
          raise build_unknown_attributes_error(unknown)
        end
      end

      def build_unknown_attributes_error(attributes)
        payload = attributes.map { |attribute| build_unknown_attribute_payload(attribute) }
        message = 'Unknown attributes were provided by endpoint'
        FunWithJsonApi::Exceptions::UnknownAttribute.new(message, payload)
      end

      def build_unknown_attribute_payload(attribute)
        ExceptionPayload.new(
          detail: unknown_attribute_error(attribute),
          pointer: "/data/attributes/#{attribute}"
        )
      end

      def build_forbidden_attribute_error(attributes)
        payload = attributes.map { |attribute| build_forbidden_attribute_payload(attribute) }
        message = 'Forbidden attributes were provided by endpoint'
        FunWithJsonApi::Exceptions::UnauthorizedAttribute.new(message, payload)
      end

      def build_forbidden_attribute_payload(attribute)
        ExceptionPayload.new(
          detail: forbidden_attribute_error(attribute),
          pointer: "/data/attributes/#{attribute}",
          status: '403'
        )
      end

      def unknown_attribute_error(attribute)
        I18n.t(
          :unknown_attribute_for_resource,
          attribute: attribute,
          resource: json_api_resource.type,
          scope: 'fun_with_json_api.schema_validators'
        )
      end

      def forbidden_attribute_error(attribute)
        I18n.t(
          :forbidden_attribute_for_request,
          attribute: attribute,
          resource: json_api_resource.type,
          scope: 'fun_with_json_api.schema_validators'
        )
      end
    end
  end
end
