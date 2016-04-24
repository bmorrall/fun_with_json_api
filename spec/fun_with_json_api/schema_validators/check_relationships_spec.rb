require 'spec_helper'

describe FunWithJsonApi::SchemaValidators::CheckRelationships do
  describe '.call' do
    let(:document) do
      {
        'data' => {
          'id' => '42',
          'type' => 'examples',
          'relationships' => {
            'foobar' => {
              'data' => relationship_data
            }
          }
        }
      }
    end
    let(:relationship_data) { double('relationship_data') }
    let(:json_api_resource) { instance_double('FunWithJsonApi::ActiveModelResource', type: 'examples') }
    let(:resource) { double('resource') }
    subject { described_class.call(json_api_resource, document, resource) }

    context 'with a has-one relationship' do
      let(:relationship) do
        instance_double('FunWithJsonApi::Relationship', name: :foobar, has_many?: false)
      end
      before { allow(json_api_resource).to receive(:relationships).and_return([relationship]) }

      context 'when the relationship item is a hash' do
        let(:relationship_data) { { 'id' => '24', 'type' => 'foobars' } }

        context 'when the type matches the relationship' do
          before { allow(relationship).to receive(:type).and_return('foobars') }

          it { is_expected.to eq true }
        end

        context 'when the type does not match the relationship' do
          before { allow(relationship).to receive(:type).and_return('invalid') }

          it 'raises a InvalidRelationshipType error' do
            expect do
              subject
            end.to raise_error(FunWithJsonApi::Exceptions::InvalidRelationshipType) do |e|
              expect(e.payload.size).to eq 1

              payload = e.payload.first
              expect(payload.code).to eq 'invalid_relationship_type'
              expect(payload.pointer).to eq '/data/relationships/foobar/data/type'
              expect(payload.title).to eq(
                'Request json_api relationship type does not match expected resource'
              )
              expect(payload.detail).to eq(
                "Expected 'foobar' relationship to be null or a 'invalid' resource identifier Hash"
              )
              expect(payload.status).to eq '409'
            end
          end
        end
      end

      context 'when the relationship item is nil' do
        let(:relationship_data) { nil }

        it { is_expected.to eq true }
      end

      context 'when the relationship item is a array' do
        let(:relationship_data) { [{ 'id' => '24', 'type' => 'foobars' }] }

        it { is_expected.to eq true }
      end
    end

    context 'with a has-many relationship' do
      let(:relationship) do
        instance_double('FunWithJsonApi::RelationshipCollection', name: :foobar, has_many?: true)
      end
      before { allow(json_api_resource).to receive(:relationships).and_return([relationship]) }

      context 'when the relationship item is a array' do
        let(:relationship_data) { [{ 'id' => '24', 'type' => 'foobars' }] }

        context 'when the type matches the relationship' do
          before { allow(relationship).to receive(:type).and_return('foobars') }

          it { is_expected.to eq true }
        end

        context 'when the type does not match the json_api_resource' do
          before { allow(relationship).to receive(:type).and_return('invalid') }

          it 'raises a InvalidRelationshipType error' do
            expect do
              subject
            end.to raise_error(FunWithJsonApi::Exceptions::InvalidRelationshipType) do |e|
              expect(e.payload.size).to eq 1

              payload = e.payload.first
              expect(payload.code).to eq 'invalid_relationship_type'
              expect(payload.pointer).to eq '/data/relationships/foobar/data/0/type'
              expect(payload.title).to eq(
                'Request json_api relationship type does not match expected resource'
              )
              expect(payload.detail).to eq(
                "Expected 'foobar' relationship to be an Array of 'invalid' resource identifiers"
              )
              expect(payload.status).to eq '409'
            end
          end
        end
      end

      context 'when the relationship item is a hash' do
        let(:relationship_data) { { 'id' => '24', 'type' => 'foobars' } }

        it { is_expected.to eq true }
      end

      context 'when the relationship item is nil' do
        let(:relationship_data) { nil }

        it { is_expected.to eq true }
      end
    end

    context 'when the document does not have an expected relationship' do
      let(:document) do
        {
          'data' => {
            'id' => '42',
            'type' => 'examples'
          }
        }
      end
      let(:relationship) do
        instance_double('FunWithJsonApi::RelationshipCollection', name: :foobar, has_many?: true)
      end
      before { allow(json_api_resource).to receive(:relationships).and_return([relationship]) }

      it { is_expected.to eq true }
    end

    context 'when the document contains an excluded relationship' do
      before do
        json_api_resource_class = class_double(
          'FunWithJsonApi::ActiveModelResource',
          relationship_names: %i(foobar)
        )
        allow(json_api_resource).to receive(:class).and_return(json_api_resource_class)
        allow(json_api_resource).to receive(:relationships).and_return([])
      end

      it 'raises a UnauthorizedRelationship error' do
        expect do
          subject
        end.to raise_error(FunWithJsonApi::Exceptions::UnauthorizedRelationship) do |e|
          expect(e.http_status).to eq 403
          expect(e.payload.size).to eq 1

          payload = e.payload.first
          expect(payload.code).to eq 'unauthorized_relationship'
          expect(payload.pointer).to eq '/data/relationships/foobar'
          expect(payload.title).to eq(
            'Request json_api relationship can not be updated by the current endpoint'
          )
          expect(payload.detail).to eq(
            "The provided relationship 'foobar' can not be assigned to a 'examples' resource"\
            ' from the current endpoint'
          )
          expect(payload.status).to eq '403'
        end
      end
    end

    context 'when the document contains an unknown relationship' do
      before do
        json_api_resource_class = class_double(
          'FunWithJsonApi::ActiveModelResource',
          relationship_names: %i(blargh)
        )
        allow(json_api_resource).to receive(:class).and_return(json_api_resource_class)
        allow(json_api_resource).to receive(:relationships).and_return([])
      end

      it 'raises a UnknownRelationship error' do
        expect do
          subject
        end.to raise_error(FunWithJsonApi::Exceptions::UnknownRelationship) do |e|
          expect(e.http_status).to eq 400
          expect(e.payload.size).to eq 1

          payload = e.payload.first
          expect(payload.code).to eq 'unknown_relationship'
          expect(payload.pointer).to eq '/data/relationships/foobar'
          expect(payload.title).to eq(
            'Request json_api relationship is not recognised by the current endpoint'
          )
          expect(payload.detail).to eq(
            "The provided relationship 'foobar' can not be directly assigned to a 'examples'"\
            ' resource, or is an unknown relationship'
          )
          expect(payload.status).to eq '400'
        end
      end
    end
  end
end
