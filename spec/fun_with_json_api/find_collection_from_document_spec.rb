require 'spec_helper'

describe FunWithJsonApi::FindCollectionFromDocument do
  describe '.find' do
    let(:json_api_resource) { instance_double('FunWithJsonApi::ActiveModelResource') }
    subject { described_class.find(document, json_api_resource) }

    context 'with a json_api_resource' do
      before { allow(json_api_resource).to receive(:type).and_return('person') }

      context 'with a document containing a resource that matches the expected type' do
        let(:document) { { data: [{ id: '42', type: 'person' }] } }

        context 'with a resource matching the document' do
          let!(:resource) { double('resource') }
          before do
            allow(json_api_resource).to receive(:load_collection_from_id_values)
              .with(['42'])
              .and_return([resource])
          end

          context 'when the resource is authorised' do
            before do
              resource_authorizer = double(:resource_authorizer)
              allow(resource_authorizer).to receive(:call).with(resource).and_return(true)
              allow(json_api_resource).to receive(:resource_authorizer).and_return(resource_authorizer)
            end

            it 'returns the resource in a array' do
              expect(subject).to eq [resource]
            end
          end

          context 'when the resource is unauthorized' do
            before do
              resource_authorizer = double(:resource_authorizer)
              allow(resource_authorizer).to receive(:call).with(resource).and_return(false)
              allow(json_api_resource).to receive(:resource_authorizer).and_return(resource_authorizer)
            end

            it 'raises a UnauthorizedResource error' do
              expect do
                subject
              end.to raise_error(FunWithJsonApi::Exceptions::UnauthorizedResource) do |e|
                expect(e.payload.size).to eq 1

                payload = e.payload.first
                expect(payload.status).to eq '403'
                expect(payload.code).to eq 'unauthorized_resource'
                expect(payload.title).to eq 'Unable to access the requested resource'
                expect(payload.detail).to eq(
                  "Unable to assign the requested 'person' (42) to the current resource"
                )
                expect(payload.pointer).to eq '/data/0'
              end
            end
          end
        end

        context 'with a single resource that cannot be found' do
          let!(:resource) { double('resource') }
          before do
            allow(json_api_resource).to receive(:load_collection_from_id_values)
              .with(['42'])
              .and_return([])
          end

          it 'raises a MissingResource error' do
            allow(json_api_resource).to receive(:id_param).and_return(:id)
            allow(json_api_resource).to receive(:resource_class).and_return(
              class_double('ActiveRecord::Base')
            )
            allow(json_api_resource).to receive(:encode_collection_ids).with([]).and_return([])

            expect { subject }.to raise_error(FunWithJsonApi::Exceptions::MissingResource) do |e|
              expect(e.payload.size).to eq 1

              payload = e.payload.first
              expect(payload.status).to eq '404'
              expect(payload.code).to eq 'missing_resource'
              expect(payload.title).to eq 'Unable to find the requested resource'
              expect(payload.detail).to eq "Unable to find 'person' with matching id: '42'"
              expect(payload.pointer).to eq '/data/0'
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
            allow(json_api_resource).to receive(:load_collection_from_id_values)
              .with(%w(42 43 44))
              .and_return([resource_a, resource_b, resource_c])
          end

          context 'when all resources are authorised' do
            before do
              resource_authorizer = double(:resource_authorizer)
              [resource_a, resource_b, resource_c].each do |resource|
                allow(resource_authorizer).to receive(:call).with(resource).and_return(true)
              end
              allow(json_api_resource).to receive(:resource_authorizer).and_return(resource_authorizer)
            end

            it 'returns all resources in a array' do
              expect(subject).to eq [resource_a, resource_b, resource_c]
            end
          end

          context 'when there are unauthorized resources' do
            before do
              resource_authorizer = double(:resource_authorizer)
              allow(resource_authorizer).to receive(:call).and_return(false)
              allow(resource_authorizer).to receive(:call).with(resource_b).and_return(true)
              allow(json_api_resource).to receive(:resource_authorizer).and_return(resource_authorizer)
            end

            it 'raises a UnauthorizedResource error' do
              expect do
                subject
              end.to raise_error(FunWithJsonApi::Exceptions::UnauthorizedResource) do |e|
                expect(e.payload.size).to eq 2

                payload = e.payload.first
                expect(payload.status).to eq '403'
                expect(payload.code).to eq 'unauthorized_resource'
                expect(payload.title).to eq 'Unable to access the requested resource'
                expect(payload.detail).to eq(
                  "Unable to assign the requested 'person' (42) to the current resource"
                )
                expect(payload.pointer).to eq '/data/0'

                payload = e.payload.second
                expect(payload.status).to eq '403'
                expect(payload.code).to eq 'unauthorized_resource'
                expect(payload.title).to eq 'Unable to access the requested resource'
                expect(payload.detail).to eq(
                  "Unable to assign the requested 'person' (44) to the current resource"
                )
                expect(payload.pointer).to eq '/data/2'
              end
            end
          end
        end

        context 'when not all resources could be found' do
          let!(:resource_a) { double('resource', code: '42') }
          let!(:resource_b) { double('resource', code: '43') }
          let!(:resource_c) { double('resource', code: '44') }
          before do
            allow(json_api_resource).to receive(:load_collection_from_id_values)
              .with(%w(42 43 44))
              .and_return([resource_b])
          end

          it 'raises a MissingResource error with a payload for each error' do
            allow(json_api_resource).to receive(:id_param).and_return(:code)
            allow(json_api_resource).to receive(:resource_class).and_return(
              class_double('ActiveRecord::Base')
            )
            allow(json_api_resource).to receive(:encode_collection_ids).with(
              [resource_b]
            ).and_return([resource_b.code])

            expect { subject }.to raise_error(FunWithJsonApi::Exceptions::MissingResource) do |e|
              expect(e.payload.size).to eq 2

              payload_a = e.payload.first
              expect(payload_a.status).to eq '404'
              expect(payload_a.code).to eq 'missing_resource'
              expect(payload_a.title).to eq 'Unable to find the requested resource'
              expect(payload_a.detail).to eq "Unable to find 'person' with matching id: '42'"
              expect(payload_a.pointer).to eq '/data/0'

              payload_b = e.payload.last
              expect(payload_b.status).to eq '404'
              expect(payload_b.code).to eq 'missing_resource'
              expect(payload_b.title).to eq 'Unable to find the requested resource'
              expect(payload_b.detail).to eq "Unable to find 'person' with matching id: '44'"
              expect(payload_b.pointer).to eq '/data/2'
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
            described_class.find(invalid_document, json_api_resource)
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
