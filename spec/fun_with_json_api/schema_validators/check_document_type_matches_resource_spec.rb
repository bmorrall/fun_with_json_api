require 'spec_helper'

describe FunWithJsonApi::SchemaValidators::CheckDocumentTypeMatchesResource do
  describe '' do
    let(:json_api_resource) do
      instance_double('FunWithJsonApi::JsonApiResource', type: resource_type)
    end
    let(:document) { { 'data' => { 'type' => document_type } } }

    context 'when document_type matches the resource_type' do
      let(:document_type) { 'foobar' }
      let(:resource_type) { 'foobar' }

      it 'does not raise any exceptions' do
        described_class.call(json_api_resource, document, double('resource'))
      end
    end

    context 'when document_type does not match resource_type' do
      let(:document_type) { 'examples' }
      let(:resource_type) { 'foobar' }

      it 'raises a InvalidDocumentType error' do
        expect do
          described_class.call(json_api_resource, document, double('resource'))
        end.to raise_error(FunWithJsonApi::Exceptions::InvalidDocumentType) do |e|
          expect(e.payload.size).to eq 1

          payload = e.payload.first
          expect(payload.code).to eq 'invalid_document_type'
          expect(payload.pointer).to eq '/data/type'
          expect(payload.title).to eq 'Request json_api data type does not match endpoint'
          expect(payload.detail).to eq "Expected data type to be a 'foobar' resource"
          expect(payload.status).to eq '409'
        end
      end
    end
  end
end
