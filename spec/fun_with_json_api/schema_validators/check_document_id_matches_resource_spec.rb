require 'spec_helper'

describe FunWithJsonApi::SchemaValidators::CheckDocumentIdMatchesResource do
  describe '.call' do
    let(:resource_id) { double(:resource_id) }
    let(:document_id) { double(:document_id) }

    let(:json_api_resource) do
      instance_double('FunWithJsonApi::ActiveModelResource', type: 'examples')
    end
    let(:document) { { 'data' => { 'id' => document_id } } }
    let(:resource) { double('resource') }
    before do
      allow(json_api_resource).to receive(:encode_id).with(resource).and_return(resource_id)
    end
    subject { described_class.call(json_api_resource, document, resource) }

    context 'when the resource is persisted' do
      let(:resource) { instance_double('ActiveRecord::Base', id: resource_id, persisted?: true) }

      context 'when /data/id does not match the resource id' do
        let(:resource_id) { '11' }
        let(:document_id) { '42' }

        it 'raises a InvalidDocumentIdentifier error' do
          expect do
            subject
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidDocumentIdentifier) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.code).to eq 'invalid_document_identifier'
            expect(payload.pointer).to eq '/data/id'
            expect(payload.title).to eq 'Request json_api data id is invalid'
            expect(payload.detail).to eq 'Expected data id to match resource at endpoint: 11'
            expect(payload.status).to eq '409'
          end
        end
      end

      context 'when /data/id is not a string' do
        let(:document_id) { 42 }

        it 'raises a InvalidDocument error' do
          expect do
            subject
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidDocumentIdentifier) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.code).to eq 'invalid_document_identifier'
            expect(payload.pointer).to eq '/data/id'
            expect(payload.title).to eq 'Request json_api data id is invalid'
            expect(payload.detail).to eq 'data id value must be a JSON String (i.e. "1234")'
            expect(payload.status).to eq '409'
          end
        end
      end
    end

    context 'when the resource is not persisted' do
      let(:resource) { instance_double('ActiveRecord::Base', persisted?: false) }

      context 'when a document_id has been supplied' do
        let(:document_id) { '42' }

        context 'when the json_api_resource does not have an id attribute' do
          before do
            allow(json_api_resource).to receive(:attributes).and_return([])
          end

          it 'raises a IllegalClientGeneratedIdentifier error' do
            expect do
              subject
            end.to raise_error(FunWithJsonApi::Exceptions::IllegalClientGeneratedIdentifier) do |e|
              expect(e.payload.size).to eq 1

              payload = e.payload.first
              expect(payload.code).to eq 'illegal_client_generated_identifier'
              expect(payload.pointer).to eq '/data/id'
              expect(payload.title).to eq(
                'Request json_api attempted to set an unsupported client-generated id'
              )
              expect(payload.detail).to eq(
                "The current endpoint does not allow you to set an id for a new 'examples' resource"
              )
              expect(payload.status).to eq '403'
            end
          end
        end
        context 'when the json_api_resource has an id attribute' do
          before do
            allow(json_api_resource).to receive(:attributes).and_return(
              [
                instance_double('FunWithJsonApi::Attribute', name: :id)
              ]
            )
          end

          context 'when /data/id is not a string' do
            let(:document_id) { 42 }

            it 'raises a InvalidDocument error' do
              expect do
                subject
              end.to raise_error(FunWithJsonApi::Exceptions::InvalidDocumentIdentifier) do |e|
                expect(e.payload.size).to eq 1

                payload = e.payload.first
                expect(payload.code).to eq 'invalid_document_identifier'
                expect(payload.pointer).to eq '/data/id'
                expect(payload.title).to eq 'Request json_api data id is invalid'
                expect(payload.detail).to eq 'data id value must be a JSON String (i.e. "1234")'
                expect(payload.status).to eq '409'
              end
            end
          end

          context 'when a resource matching id exists' do
            before do
              allow(json_api_resource).to receive(:load_resource_from_id_value)
                .with('42')
                .and_return(double('existing_resource', id: '24'))
            end

            it 'raises a InvalidClientGeneratedIdentifier error' do
              expect do
                subject
              end.to raise_error(
                FunWithJsonApi::Exceptions::InvalidClientGeneratedIdentifier
              ) do |e|
                expect(e.payload.size).to eq 1

                payload = e.payload.first
                expect(payload.code).to eq 'invalid_client_generated_identifier'
                expect(payload.pointer).to eq '/data/id'
                expect(payload.title).to eq(
                  'Request json_api data id has already been used for an existing'\
                  ' resource'
                )
                expect(payload.detail).to eq(
                  "The provided id for a new 'examples' resource has already been used by another"\
                  ' resource: 42'
                )
                expect(payload.status).to eq '409'
              end
            end
          end
        end
      end
    end
  end
end
