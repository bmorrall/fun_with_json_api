require 'spec_helper'

describe FunWithJsonApi::SchemaValidator do
  let(:document) { { data: { id: '42', type: 'examples' } } }
  let(:json_api_resource) { instance_double('FunWithJsonApi::ActiveModelResource') }
  let(:resource) { double('Resource') }
  subject(:instance) { described_class.send :new, document, json_api_resource, resource }

  describe '.check' do
    it 'calls all schema validator checks with an instance of itself' do
      sanitized_document = document.deep_stringify_keys

      [
        FunWithJsonApi::SchemaValidators::CheckDocumentTypeMatchesResource,
        FunWithJsonApi::SchemaValidators::CheckDocumentIdMatchesResource,
        FunWithJsonApi::SchemaValidators::CheckAttributeNames,
        FunWithJsonApi::SchemaValidators::CheckRelationships
      ].each do |property_check|
        expect(property_check).to receive(:call).with(
          json_api_resource, sanitized_document, resource
        )
      end

      described_class.check(json_api_resource, document, resource)
    end
  end
end
