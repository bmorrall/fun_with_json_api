module FunWithJsonApi
  class Configuration
    attr_accessor :force_render_encode_errors_as_json_api
    alias force_render_encode_errors_as_json_api? force_render_encode_errors_as_json_api

    def initialize
      @force_render_encode_errors_as_json_api = false
    end
  end
end
