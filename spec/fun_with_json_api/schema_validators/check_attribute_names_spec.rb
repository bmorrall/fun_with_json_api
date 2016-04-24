require 'spec_helper'

describe FunWithJsonApi::SchemaValidators::CheckAttributeNames do
  describe '.call' do
    let(:document) do
      {
        'data' => {
          'id' => '42',
          'type' => 'examples',
          'attributes' => {
            'foobar' => 'blargh'
          }
        }
      }
    end
    let(:json_api_resource) { instance_double('FunWithJsonApi::ActiveModelResource', type: 'examples') }
    subject { described_class.call(json_api_resource, document, double('resource')) }

    context 'when the document contains an attribute supported by the json_api_resource' do
      let(:attribute) { instance_double('FunWithJsonApi::Attribute', name: :foobar) }
      before { allow(json_api_resource).to receive(:attributes).and_return([attribute]) }

      it 'returns true' do
        expect(subject).to eq true
      end
    end

    context 'when the document contains an disabled attribute' do
      before do
        json_api_resource_class = class_double(
          'FunWithJsonApi::ActiveModelResource',
          attribute_names: %i(foobar)
        )
        allow(json_api_resource).to receive(:class).and_return(json_api_resource_class)
        allow(json_api_resource).to receive(:attributes).and_return([])
      end

      it 'raises a UnauthorizedAttribute error' do
        expect do
          subject
        end.to raise_error(FunWithJsonApi::Exceptions::UnauthorizedAttribute) do |e|
          expect(e.http_status).to eq 403
          expect(e.payload.size).to eq 1

          payload = e.payload.first
          expect(payload.code).to eq 'unauthorized_attribute'
          expect(payload.pointer).to eq '/data/attributes/foobar'
          expect(payload.title).to eq(
            'Request json_api attribute can not be updated by the current endpoint'
          )
          expect(payload.detail).to eq(
            "The provided attribute 'foobar' can not be assigned to a 'examples' resource"\
            ' from the current endpoint'
          )
          expect(payload.status).to eq '403'
        end
      end
    end

    context 'when the document contains an unknown attribute' do
      before do
        json_api_resource_class = class_double(
          'FunWithJsonApi::ActiveModelResource',
          attribute_names: %i(blargh)
        )
        allow(json_api_resource).to receive(:class).and_return(json_api_resource_class)
        allow(json_api_resource).to receive(:attributes).and_return([])
      end

      it 'raises a UnknownAttribute error' do
        expect do
          subject
        end.to raise_error(FunWithJsonApi::Exceptions::UnknownAttribute) do |e|
          expect(e.payload.size).to eq 1

          payload = e.payload.first
          expect(payload.code).to eq 'unknown_attribute'
          expect(payload.pointer).to eq '/data/attributes/foobar'
          expect(payload.title).to eq(
            'Request json_api attribute is not recognised by the current endpoint'
          )
          expect(payload.detail).to eq(
            "The provided attribute 'foobar' can not be assigned to a 'examples' resource"
          )
          expect(payload.status).to eq '400'
        end
      end
    end
  end
end
