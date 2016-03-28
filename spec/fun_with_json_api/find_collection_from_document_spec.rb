require 'spec_helper'

describe FunWithJsonApi::FindCollectionFromDocument do
  describe '.find' do
    let(:deserializer) { instance_double('FunWithJsonApi::Deserializer') }
    subject { described_class.find(document, deserializer) }

    context 'with a deserializer' do
      before { allow(deserializer).to receive(:type).and_return('person') }

      context 'with a document containing a resource that matches the expected type' do
        let(:document) { { data: [{ id: '42', type: 'person' }] } }

        context 'with a resource matching the document' do
          let!(:resource) { double('resource') }
          before do
            allow(deserializer).to receive(:load_collection_from_id_values)
              .with(['42'])
              .and_return([resource])
          end

          it 'returns the resource in a array' do
            expect(subject).to eq [resource]
          end
        end

        context 'with a single resource that cannot be found' do
          let!(:resource) { double('resource') }
          before do
            allow(deserializer).to receive(:load_collection_from_id_values)
              .with(['42'])
              .and_return([])
          end

          it 'raises a MissingResource error' do
            allow(deserializer).to receive(:id_param).and_return(:id)
            allow(deserializer).to receive(:resource_class).and_return(
              class_double('ActiveRecord::Base')
            )
            allow(deserializer).to receive(:format_collection_ids).with([]).and_return([])

            expect { subject }.to raise_error(FunWithJsonApi::Exceptions::MissingResource) do |e|
              expect(e.payload.size).to eq 1

              payload = e.payload.first
              expect(payload.status).to eq '404'
              expect(payload.code).to eq 'missing_resource'
              expect(payload.title).to eq 'Unable to find the requested resource'
              expect(payload.detail).to eq "Unable to find 'person' with matching id: '42'"
              expect(payload.pointer).to eq '/data/0/id'
            end
          end
        end
      end

      context 'with a document containing multiple resource that matches the expected type' do
        let(:document) do
          {
            data: [
              { id: '42', type: 'person' },
              { id: '43', type: 'person' },
              { id: '44', type: 'person' }
            ]
          }
        end

        context 'when all resources can be found' do
          let!(:resource_a) { double('resource', code: '42') }
          let!(:resource_b) { double('resource', code: '43') }
          let!(:resource_c) { double('resource', code: '44') }
          before do
            allow(deserializer).to receive(:load_collection_from_id_values)
              .with(%w(42 43 44))
              .and_return([resource_a, resource_b, resource_c])
          end

          it 'returns all resources in a array' do
            expect(subject).to eq [resource_a, resource_b, resource_c]
          end
        end

        context 'when not all resources could be found' do
          let!(:resource_a) { double('resource', code: '42') }
          let!(:resource_b) { double('resource', code: '43') }
          let!(:resource_c) { double('resource', code: '44') }
          before do
            allow(deserializer).to receive(:load_collection_from_id_values)
              .with(%w(42 43 44))
              .and_return([resource_b])
          end

          it 'raises a MissingResource error with a payload for each error' do
            allow(deserializer).to receive(:id_param).and_return(:code)
            allow(deserializer).to receive(:resource_class).and_return(
              class_double('ActiveRecord::Base')
            )
            allow(deserializer).to receive(:format_collection_ids).with(
              [resource_b]
            ).and_return([resource_b.code])

            expect { subject }.to raise_error(FunWithJsonApi::Exceptions::MissingResource) do |e|
              expect(e.payload.size).to eq 2

              payload_a = e.payload.first
              expect(payload_a.status).to eq '404'
              expect(payload_a.code).to eq 'missing_resource'
              expect(payload_a.title).to eq 'Unable to find the requested resource'
              expect(payload_a.detail).to eq "Unable to find 'person' with matching id: '42'"
              expect(payload_a.pointer).to eq '/data/0/id'

              payload_b = e.payload.last
              expect(payload_b.status).to eq '404'
              expect(payload_b.code).to eq 'missing_resource'
              expect(payload_b.title).to eq 'Unable to find the requested resource'
              expect(payload_b.detail).to eq "Unable to find 'person' with matching id: '44'"
              expect(payload_b.pointer).to eq '/data/2/id'
            end
          end
        end
      end

      context 'with a document containing a resource that does not match the expected type' do
        let(:document) { { data: [{ id: '42', type: 'blargh' }] } }

        it 'raises a InvalidDocumentType error' do
          expect { subject }.to raise_error(FunWithJsonApi::Exceptions::InvalidDocumentType) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.code).to eq 'invalid_document_type'
            expect(payload.pointer).to eq '/data/0/type'
            expect(payload.title).to eq 'Request json_api data type does not match endpoint'
            expect(payload.detail).to eq "Expected 'blargh' to be a 'person' resource"
            expect(payload.status).to eq '409'
          end
        end
      end

      context 'with a document containing multiple resources that does not match' do
        let(:document) do
          {
            data: [
              { id: '42', type: 'person' },
              { id: '43', type: 'foobar' },
              { id: '44', type: 'blargh' }
            ]
          }
        end

        it 'raises a InvalidDocumentType error with a payload for each error' do
          expect { subject }.to raise_error(FunWithJsonApi::Exceptions::InvalidDocumentType) do |e|
            expect(e.payload.size).to eq 2

            payload_a = e.payload.first
            expect(payload_a.code).to eq 'invalid_document_type'
            expect(payload_a.pointer).to eq '/data/1/type'
            expect(payload_a.title).to eq 'Request json_api data type does not match endpoint'
            expect(payload_a.detail).to eq "Expected 'foobar' to be a 'person' resource"
            expect(payload_a.status).to eq '409'

            payload_b = e.payload.last
            expect(payload_b.code).to eq 'invalid_document_type'
            expect(payload_b.pointer).to eq '/data/2/type'
            expect(payload_b.title).to eq 'Request json_api data type does not match endpoint'
            expect(payload_b.detail).to eq "Expected 'blargh' to be a 'person' resource"
            expect(payload_b.status).to eq '409'
          end
        end
      end

      context 'with a document containing an empty array' do
        let(:document) { { data: [] } }

        it 'returns an empty array' do
          expect(subject).to eq([])
        end
      end
    end

    context 'with a malformed document' do
      it 'raises a InvalidDocument error' do
        [
          { id: 'foo' },
          { data: 'string' },
          { data: { id: '42', type: 'person' } }
        ].each do |invalid_document|
          expect do
            described_class.find(invalid_document, deserializer)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidDocument) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.code).to eq 'invalid_document'
            expect(payload.pointer).to eq '/data'
            expect(payload.title).to eq 'Request json_api document is invalid'
            expect(payload.detail).to eq 'Expected data to be an Array of resources'
            expect(payload.status).to eq '400'
          end
        end
      end
    end
  end
end
