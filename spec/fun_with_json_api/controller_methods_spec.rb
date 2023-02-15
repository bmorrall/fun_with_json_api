require 'spec_helper'

describe FunWithJsonApi::ControllerMethods, type: :controller do
  describe '#render_fun_with_json_api_exception' do
    context 'with a controller that raises an exception' do
      controller do
        # rubocop:disable RSpec/DescribedClass
        include FunWithJsonApi::ControllerMethods
        # rubocop:enable RSpec/DescribedClass

        rescue_from FunWithJsonApi::Exception, with: :render_fun_with_json_api_exception

        attr_accessor :fun_with_json_api_exception

        def index
          raise fun_with_json_api_exception
        end
      end

      let(:payload) { [] }
      let(:exception) { FunWithJsonApi::Exception.new('document is invalid!', payload) }
      before { controller.fun_with_json_api_exception = exception }

      context 'with a full exception payload' do
        let(:payload) do
          FunWithJsonApi::ExceptionPayload.new(
            id: '123',
            status: '403',
            code: 'text_exception',
            title: 'Test Example Title',
            detail: 'Test Example Details',
            pointer: '/data/attributes/example',
            parameter: 'example'
          )
        end

        it 'returns a json api error status' do
          get :index
          expect(response.status).to eq 403
          expect(response.content_type).to include('application/vnd.api+json')
        end

        it 'renders the exception payload as a json api errors response' do
          get :index
          expect(JSON.parse(response.body)).to eq(
            'errors' => [
              {
                'id' => '123',
                'status' => '403',
                'code' => 'text_exception',
                'title' => 'Test Example Title',
                'detail' => 'Test Example Details',
                'source' => {
                  'pointer' => '/data/attributes/example',
                  'parameter' => 'example'
                }
              }
            ]
          )
        end
      end

      context 'when the exception has multiple payloads' do
        let(:payload) do
          [
            FunWithJsonApi::ExceptionPayload.new(
              status: '403',
              code: 'text_exception'
            ),
            FunWithJsonApi::ExceptionPayload.new(
              status: '403',
              detail: 'This is an example'
            )
          ]
        end

        it 'returns a json api error status' do
          get :index
          expect(response.status).to eq 403
          expect(response.content_type).to include('application/vnd.api+json')
        end

        it 'renders all exception payload items' do
          get :index
          expect(JSON.parse(response.body)).to eq(
            'errors' => [
              {
                'status' => '403',
                'code' => 'text_exception'
              },
              {
                'status' => '403',
                'detail' => 'This is an example'
              }
            ]
          )
        end
      end

      context 'with a partial ExceptionPayload' do
        let(:payload) do
          FunWithJsonApi::ExceptionPayload.new(
            status: '422',
            code: 'text_exception'
          )
        end

        it 'returns a json api error status' do
          get :index
          expect(response.status).to eq 422
          expect(response.content_type).to include('application/vnd.api+json')
        end

        it 'only renders the non-nil params' do
          get :index
          expect(JSON.parse(response.body)).to eq(
            'errors' => [
              {
                'status' => '422',
                'code' => 'text_exception'
              }
            ]
          )
        end
      end
    end
  end
end
