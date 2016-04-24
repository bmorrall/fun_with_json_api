module FunWithJsonApi
  module Exceptions
    # Indicates a supplied attribute value is unknown to the current json_api_resource
    class UnknownAttribute < FunWithJsonApi::Exception
      def initialize(message, payload = ExceptionPayload.new)
        payload = Array.wrap(payload).each do |unknown|
          unknown.code ||= 'unknown_attribute'
          unknown.title ||= I18n.t(:unknown_attribute, scope: 'fun_with_json_api.exceptions')
          unknown.status ||= '400'
        end
        super
      end
    end
  end
end
