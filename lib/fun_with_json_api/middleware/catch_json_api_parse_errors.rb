module FunWithJsonApi
  module Middleware
    class CatchJsonApiParseErrors
      JSON_API_REGEX = %r{application\/vnd\.api\+json}

      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      rescue ActionDispatch::ParamsParser::ParseError => error
        if env['CONTENT_TYPE'] =~ JSON_API_REGEX && respond_with_json_api_error?(env)
          build_json_api_encode_error_response
        else
          raise error
        end
      end

      private

      def build_json_api_encode_error_response
        title = I18n.t('fun_with_json_api.exceptions.invalid_request_body')
        [
          400, { 'Content-Type' => FunWithJsonApi::MEDIA_TYPE },
          [
            { errors: [{ code: 'invalid_request_body', title: title, status: '400' }] }.to_json
          ]
        ]
      end

      def respond_with_json_api_error?(env)
        FunWithJsonApi.configuration.force_render_encode_errors_as_json_api? ||
          env['HTTP_ACCEPT'] =~ JSON_API_REGEX
      end
    end
  end
end
