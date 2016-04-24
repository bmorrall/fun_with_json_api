require 'spec_helper'

describe 'Request Parsing', type: :request do
  it 'converts a json_api request body into param values' do
    request_data = '{"data":{"id":"42","type":"foobar"}}'

    post '/echo', request_data, 'Accept': 'application/vnd.api+json',
                                'Content-Type': 'application/vnd.api+json'
    expect(
      JSON.parse(response.body, symbolize_names: true)
    ).to eq(data: { id: '42', type: 'foobar' })
  end

  context 'with invalid json api request data' do
    let(:invalid_request_data) { '{"data":{"id":"42","type":"foobar",}}' } # extra comma

    context 'when force_render_encode_errors_as_json_api? is true' do
      before do
        FunWithJsonApi.configure do |config|
          config.force_render_encode_errors_as_json_api = true
        end
      end

      context 'when the request has a json api accept header' do
        it 'renders a json api invalid document response' do
          post '/echo',
               invalid_request_data,
               'Accept': 'application/vnd.api+json',
               'Content-Type': 'application/vnd.api+json'

          expect(response.status).to eq 400
          expect(JSON.parse(response.body, symbolize_names: true)).to eq(
            errors: [{
              code: 'invalid_request_body',
              title: 'Request json_api body could not be parsed',
              status: '400'
            }])
        end
      end

      context 'when the request has a json api accept header with utf-8 charset' do
        it 'renders a json api invalid document response' do
          post '/echo',
               invalid_request_data,
               'Accept': 'application/vnd.api+json; charset=utf-8',
               'Content-Type': 'application/vnd.api+json; charset=utf-8'

          expect(response.status).to eq 400
          expect(JSON.parse(response.body, symbolize_names: true)).to eq(
            errors: [{
              code: 'invalid_request_body',
              title: 'Request json_api body could not be parsed',
              status: '400'
            }])
        end
      end

      context 'when the request does not have a json api accept header' do
        it 'renders a json api invalid document response' do
          invalid_request_data = '{"data":{"id":"42","type":"foobar",}}' # extra comma

          post '/echo', invalid_request_data, 'Content-Type': 'application/vnd.api+json'

          expect(response.status).to eq 400
        end
      end
    end

    context 'when force_render_encode_errors_as_json_api? is false' do
      before do
        FunWithJsonApi.configure do |config|
          config.force_render_encode_errors_as_json_api = false
        end
      end

      context 'when the request has a json api accept header' do
        it 'renders a json api invalid document response' do
          post '/echo',
               invalid_request_data,
               'Accept': 'application/vnd.api+json',
               'Content-Type': 'application/vnd.api+json'

          expect(response.status).to eq 400
        end
      end

      context 'when the request does not have a json api accept header' do
        it 'raises a ActionDispatch::ParamsParser::ParseError' do
          expect do
            post '/echo', invalid_request_data, 'Content-Type': 'application/vnd.api+json'
          end.to raise_error(ActionDispatch::ParamsParser::ParseError)
        end
      end
    end
  end
end
