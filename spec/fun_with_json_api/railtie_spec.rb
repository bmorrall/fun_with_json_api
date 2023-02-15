require 'spec_helper'

describe FunWithJsonApi::Railtie do
  describe 'controller parameters' do
    context 'with a application/vnd.api+json request content-type', type: :controller do
      controller do
        def index
          # Concatinates /data/id and /data/type from a json_api request
          render plain: "#{params[:data][:id]}:#{params['data']['type']}"
        end
      end

      it 'converts the request body into param values' do
        json_api_data = { data: { id: '42', type: 'foobar' } }

        request.headers['Content-Type'] = 'application/vnd.api+json'
        get :index, params: json_api_data.as_json
        expect(response.body).to eq '42:foobar'
      end
    end
    context 'with an implicit respond_to json_api block', type: :controller do
      controller do
        def index
          respond_to do |format|
            format.json_api { render plain: 'passed' }
            format.all { render plain: 'failed' }
          end
        end
      end

      it 'responds to a json_api format request' do
        get :index, format: :json_api
        expect(response.body).to eq 'passed'
      end
      it 'responds to a application/vnd.api+json accept header' do
        request.headers['HTTP_ACCEPT'] = 'application/vnd.api+json'
        get :index
        expect(response.body).to eq 'passed'
      end
    end
  end

  describe 'controller rendering' do
    context 'with an explicit render json_api call', type: :controller do
      controller do
        def index
          render json_api: { data: { id: '42', type: 'foobar' } }
        end
      end

      it 'renders out the hash as a json_api response' do
        get :index
        expect(response.content_type).to include('application/vnd.api+json')
        expect(JSON.parse(response.body)).to eq(
          'data' => { 'id' => '42', 'type' => 'foobar' }
        )
      end
    end
    context 'with a resource and a serializer', type: :controller do
      controller do
        def index
          author = ARModels::Author.new(id: 42, name: 'Foo Bar')
          render json_api: author, serializer: ARModels::AuthorSerializer
        end
      end

      it 'renders the resource as a json api document' do
        get :index
        expect(response.content_type).to include('application/vnd.api+json')
        expect(JSON.parse(response.body)).to eq(
          'data' => {
            'id' => '42',
            'type' => 'person',
            'attributes' => {
              'name' => 'Foo Bar'
            },
            'relationships' => {
              'posts' => {
                'data' => []
              }
            }
          }
        )
      end
    end
  end
end
