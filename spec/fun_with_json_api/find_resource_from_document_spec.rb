require 'spec_helper'

describe FunWithJsonApi::FindResourceFromDocument do
  describe '.find' do
    let(:deserializer) { instance_double('FunWithJsonApi::Deserializer') }
    subject { described_class.find(document, deserializer) }

    context 'with a document containing a resource' do
      let(:document) { { data: { id: '42', type: 'person' } } }

      context 'with a deserializer that matches the document' do
        before { allow(deserializer).to receive(:type).and_return('person') }

        context 'with a resource matching the document' do
          let!(:resource) { double('resource') }
          before do
            allow(deserializer).to receive(:load_resource_from_id_value)
              .with('42')
              .and_return(resource)
          end

          context 'when the resource is authorised' do
            before do
              resource_authorizer = double(:resource_authorizer)
              allow(resource_authorizer).to receive(:call).with(resource).and_return(true)
              allow(deserializer).to receive(:resource_authorizer).and_return(resource_authorizer)
            end

            it 'returns the resource' do
              expect(subject).to eq resource
            end
          end

          context 'when the resource is unauthorized' do
            before do
              resource_authorizer = double(:resource_authorizer)
              allow(resource_authorizer).to receive(:call).with(resource).and_return(false)
              allow(deserializer).to receive(:resource_authorizer).and_return(resource_authorizer)
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
                expect(payload.pointer).to eq '/data'
              end
            end
          end
        end

        context 'when a resource cannot be found' do
          let!(:resource) { double('resource') }
          before do
            allow(deserializer).to receive(:load_resource_from_id_value)
              .with('42')
              .and_return(nil)
          end

          context 'with a soft deleted resource' do
            before do
              allow(deserializer).to receive(:resource_is_soft_deleted?).with('42').and_return(true)
            end

            it 'raises a MissingResource error' do
              allow(deserializer).to receive(:id_param).and_return(:id)

              expect { subject }.to raise_error(FunWithJsonApi::Exceptions::MissingResource) do |e|
                expect(e.http_status).to eq 404
                expect(e.payload.size).to eq 1

                payload = e.payload.first
                expect(payload.status).to eq '410'
                expect(payload.code).to eq 'missing_resource'
                expect(payload.title).to eq 'Unable to find the requested resource'
                expect(payload.detail).to eq "Unable to find 'person' with matching id: '42'"
                expect(payload.pointer).to eq '/data'
              end
            end
          end

          context 'with a non-existant resource' do
            before do
              allow(deserializer).to receive(:resource_is_soft_deleted?).with('42')
                .and_return(false)
            end

            it 'raises a MissingResource error' do
              allow(deserializer).to receive(:id_param).and_return(:id)

              expect { subject }.to raise_error(FunWithJsonApi::Exceptions::MissingResource) do |e|
                expect(e.http_status).to eq 404
                expect(e.payload.size).to eq 1

                payload = e.payload.first
                expect(payload.status).to eq '404'
                expect(payload.code).to eq 'missing_resource'
                expect(payload.title).to eq 'Unable to find the requested resource'
                expect(payload.detail).to eq "Unable to find 'person' with matching id: '42'"
                expect(payload.pointer).to eq '/data'
              end
            end
          end
        end
      end

      context 'when the deserializer type does not match the document' do
        before { allow(deserializer).to receive(:type).and_return('blargh') }

        it 'raises a InvalidDocumentType error' do
          expect { subject }.to raise_error(FunWithJsonApi::Exceptions::InvalidDocumentType) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.code).to eq 'invalid_document_type'
            expect(payload.pointer).to eq '/data/type'
            expect(payload.title).to eq 'Request json_api data type does not match endpoint'
            expect(payload.detail).to eq "Expected data type to be a 'blargh' resource"
            expect(payload.status).to eq '409'
          end
        end
      end
    end

    context 'with a document containing a null data atttribute' do
      let(:document) { { data: nil } }

      it 'returns nil' do
        expect(subject).to eq(nil)
      end
    end

    context 'with a malformed document' do
      it 'raises a InvalidDocument error' do
        [
          { id: 'foo' },
          { data: 'string' },
          { data: [{ id: 'foo', type: 'bar' }] }
        ].each do |invalid_document|
          expect do
            described_class.find(invalid_document, deserializer)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidDocument) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.code).to eq 'invalid_document'
            expect(payload.pointer).to eq '/data'
            expect(payload.title).to eq 'Request json_api document is invalid'
            expect(payload.detail).to eq 'Expected data to be a Hash or null'
            expect(payload.status).to eq '400'
          end
        end
      end
    end
  end
end
