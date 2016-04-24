require 'spec_helper'

describe FunWithJsonApi::ActiveModelResource do
  describe '#decode_{relationship}_relationship' do
    context 'with a ARModels::Author relationship with a "code" id param' do
      let(:json_api_resource) do
        author_json_api_resource_class = Class.new(described_class) do
          id_param 'code'
          type 'persons'
          resource_class ARModels::Author
        end

        # Build the ApiResource
        Class.new(described_class) do
          belongs_to :example, author_json_api_resource_class
        end.create
      end

      it 'finds a resource by the defined id_param and returns the resource id' do
        author = ARModels::Author.create(id: 1, code: 'foobar')
        expect(json_api_resource.decode_example_relationship('foobar')).to eq author.id
      end

      it 'raises a MissingRelationship when unable to find the resource' do
        expect do
          json_api_resource.decode_example_relationship 'foobar'
        end.to raise_error(FunWithJsonApi::Exceptions::MissingRelationship) do |e|
          expect(e.message).to eq "Couldn't find ARModels::Author where code = \"foobar\""
          expect(e.payload.size).to eq 1

          payload = e.payload.first
          expect(payload.status).to eq '404'
          expect(payload.code).to eq 'missing_relationship'
          expect(payload.title).to eq 'Unable to find the requested relationship'
          expect(payload.pointer).to eq '/data/relationships/example'
          expect(payload.detail).to eq "Unable to find 'persons' with matching id: \"foobar\""
        end
      end

      it 'raises a InvalidRelationship when given an array value' do
        expect do
          json_api_resource.decode_example_relationship %w(1 2)
        end.to raise_error(FunWithJsonApi::Exceptions::InvalidRelationship) do |e|
          expect(e.payload.size).to eq 1

          payload = e.payload.first
          expect(payload.status).to eq '400'
          expect(payload.code).to eq 'invalid_relationship'
          expect(payload.title).to eq I18n.t('fun_with_json_api.exceptions.invalid_relationship')
          expect(payload.pointer).to eq '/data/relationships/example'
          expect(payload.detail).to be_kind_of(String)
        end
      end
    end

    context 'with a ARModels::Author relationship collection with a "code" id param' do
      let(:json_api_resource) do
        author_json_api_resource_class = Class.new(described_class) do
          id_param 'code'
          type 'persons'
          resource_class ARModels::Author
        end

        # Build the ApiResource
        Class.new(described_class) do
          has_many :examples, author_json_api_resource_class
        end.create
      end

      context 'with multiple resources' do
        let!(:author_a) { ARModels::Author.create(id: 1, code: 'foobar') }
        let!(:author_b) { ARModels::Author.create(id: 2, code: 'blargh') }

        context 'when all resources are authorised' do
          before do
            resource_authorizer = double(:resource_authorizer)
            allow(resource_authorizer).to receive(:call).and_return(true)
            allow(json_api_resource.relationship_for(:examples).json_api_resource).to(
              receive(:resource_authorizer).and_return(resource_authorizer)
            )
          end

          it 'finds a resource by the defined id_param and returns the resource id' do
            expect(json_api_resource.decode_examples_relationship(%w(foobar blargh))).to eq(
              [author_a.id, author_b.id]
            )
          end
        end

        context 'when a resource is not authorised' do
          before do
            resource_authorizer = double(:resource_authorizer)
            allow(resource_authorizer).to receive(:call).and_return(false)
            allow(resource_authorizer).to receive(:call).with(author_b).and_return(false)
            allow(resource_authorizer).to receive(:call).with(author_a).and_return(true)
            allow(json_api_resource.relationship_for(:examples).json_api_resource).to(
              receive(:resource_authorizer).and_return(resource_authorizer)
            )
          end

          it 'raises a UnauthorizedResource when unable to find a single resource' do
            expect do
              json_api_resource.decode_examples_relationship %w(foobar blargh)
            end.to raise_error(FunWithJsonApi::Exceptions::UnauthorizedResource) do |e|
              expect(e.payload.size).to eq 1

              payload = e.payload.first
              expect(payload.status).to eq '403'
              expect(payload.code).to eq 'unauthorized_resource'
              expect(payload.title).to eq 'Unable to access the requested resource'
              expect(payload.pointer).to eq '/data/relationships/examples/data/1'
              expect(payload.detail).to eq(
                "Unable to assign the requested 'persons' (blargh) to the current resource"
              )
            end
          end
        end
      end

      it 'raises a MissingRelationship when unable to find a single resource' do
        ARModels::Author.create(id: 1, code: 'foobar')

        expect do
          json_api_resource.decode_examples_relationship %w(foobar blargh)
        end.to raise_error(FunWithJsonApi::Exceptions::MissingRelationship) do |e|
          expect(e.message).to eq "Couldn't find ARModels::Author items with code in [\"blargh\"]"
          expect(e.payload.size).to eq 1

          payload = e.payload.first
          expect(payload.status).to eq '404'
          expect(payload.code).to eq 'missing_relationship'
          expect(payload.title).to eq 'Unable to find the requested relationship'
          expect(payload.pointer).to eq '/data/relationships/examples/data/1'
          expect(payload.detail).to eq "Unable to find 'persons' with matching id: \"blargh\""
        end
      end

      it 'raises a MissingRelationship with a payload for all missing resources' do
        expect do
          json_api_resource.decode_examples_relationship %w(foobar blargh)
        end.to raise_error(FunWithJsonApi::Exceptions::MissingRelationship) do |e|
          expect(e.message).to eq(
            "Couldn't find ARModels::Author items with code in [\"foobar\", \"blargh\"]"
          )
          expect(e.payload.size).to eq 2

          payload_a = e.payload.first
          expect(payload_a.status).to eq '404'
          expect(payload_a.code).to eq 'missing_relationship'
          expect(payload_a.title).to eq 'Unable to find the requested relationship'
          expect(payload_a.pointer).to eq '/data/relationships/examples/data/0'
          expect(payload_a.detail).to eq "Unable to find 'persons' with matching id: \"foobar\""

          payload_b = e.payload.last
          expect(payload_b.status).to eq '404'
          expect(payload_b.code).to eq 'missing_relationship'
          expect(payload_b.title).to eq 'Unable to find the requested relationship'
          expect(payload_b.pointer).to eq '/data/relationships/examples/data/1'
          expect(payload_b.detail).to eq "Unable to find 'persons' with matching id: \"blargh\""
        end
      end

      it 'raises a InvalidRelationship when given a non-array value' do
        expect do
          json_api_resource.decode_examples_relationship '1'
        end.to raise_error(FunWithJsonApi::Exceptions::InvalidRelationship) do |e|
          expect(e.payload.size).to eq 1

          payload = e.payload.first
          expect(payload.status).to eq '400'
          expect(payload.code).to eq 'invalid_relationship'
          expect(payload.title).to eq I18n.t('fun_with_json_api.exceptions.invalid_relationship')
          expect(payload.pointer).to eq '/data/relationships/examples'
          expect(payload.detail).to be_kind_of(String)
        end
      end
    end
  end
end
