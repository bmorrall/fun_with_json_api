require 'spec_helper'

describe FunWithJsonApi::ActiveModelSerializers::PreDeserializer do
  describe '.parse' do
    describe 'document attributes parsing' do
      it 'converts known attribute values into a hash' do
        json_api_resource = Class.new(FunWithJsonApi::ActiveModelResource) do
          attribute :foo
        end.create

        document = {
          data: {
            attributes: {
              foo: 'bar'
            }
          }
        }.deep_stringify_keys!

        expect(described_class.parse(document, json_api_resource)).to eq(
          foo: 'bar'
        )
      end
      it 'handles renamed attributes' do
        json_api_resource = Class.new(FunWithJsonApi::ActiveModelResource) do
          attribute :foo, as: :blargh
        end.create

        document = {
          data: {
            attributes: {
              foo: 'bar'
            }
          }
        }.deep_stringify_keys!

        expect(described_class.parse(document, json_api_resource)).to eq(
          blargh: 'bar'
        )
      end
      it 'only returns known attributes' do
        json_api_resource = Class.new(FunWithJsonApi::ActiveModelResource) do
          attribute :foo
        end.create

        document = {
          data: {
            attributes: {
              foo: 'bar',
              blargh: 'baz'
            }
          }
        }.deep_stringify_keys!

        expect(described_class.parse(document, json_api_resource)).to eq(
          foo: 'bar'
        )
      end
    end

    describe 'single relationship parsing' do
      it 'outputs single relationship values with a _id suffix' do
        foo_json_api_resource_class = Class.new(FunWithJsonApi::ActiveModelResource)
        json_api_resource = Class.new(FunWithJsonApi::ActiveModelResource) do
          belongs_to :foo, foo_json_api_resource_class
        end.create

        document = {
          data: {
            relationships: {
              foo: {
                data: { id: '42', type: 'foos' }
              }
            }
          }
        }.deep_stringify_keys!

        expect(described_class.parse(document, json_api_resource)).to eq(
          foo_id: '42'
        )
      end
      it 'handles renamed relationships' do
        foo_json_api_resource_class = Class.new(FunWithJsonApi::ActiveModelResource)
        json_api_resource = Class.new(FunWithJsonApi::ActiveModelResource) do
          belongs_to :foo, foo_json_api_resource_class, as: :blargh
        end.create

        document = {
          data: {
            relationships: {
              foo: {
                data: { id: '42', type: 'foos' }
              }
            }
          }
        }.deep_stringify_keys!

        expect(described_class.parse(document, json_api_resource)).to eq(
          blargh_id: '42'
        )
      end
      it 'only returns known relationships' do
        foo_json_api_resource_class = Class.new(FunWithJsonApi::ActiveModelResource)
        json_api_resource = Class.new(FunWithJsonApi::ActiveModelResource) do
          belongs_to :foo, foo_json_api_resource_class
        end.create

        document = {
          data: {
            relationships: {
              foo: {
                data: { id: '42', type: 'foos' }
              },
              blargh: {
                data: { id: '24', type: 'blarghs' }
              }
            }
          }
        }.deep_stringify_keys!

        expect(described_class.parse(document, json_api_resource)).to eq(
          foo_id: '42'
        )
      end
    end

    describe 'relationship collection parsing' do
      it 'outputs singular relationship values with a _ids suffix' do
        foo_json_api_resource_class = Class.new(FunWithJsonApi::ActiveModelResource)
        json_api_resource = Class.new(FunWithJsonApi::ActiveModelResource) do
          has_many :foos, foo_json_api_resource_class
        end.create

        document = {
          data: {
            relationships: {
              foos: {
                data: [{ id: '42', type: 'foos' }, { id: '24', type: 'foos' }]
              }
            }
          }
        }.deep_stringify_keys!

        expect(described_class.parse(document, json_api_resource)).to eq(
          foo_ids: %w(42 24)
        )
      end
      it 'handles renamed relationships' do
        foo_json_api_resource_class = Class.new(FunWithJsonApi::ActiveModelResource)
        json_api_resource = Class.new(FunWithJsonApi::ActiveModelResource) do
          has_many :foos, foo_json_api_resource_class, as: :blargh
        end.create

        document = {
          data: {
            relationships: {
              foos: {
                data: [{ id: '42', type: 'foos' }, { id: '11', type: 'foos' }]
              }
            }
          }
        }.deep_stringify_keys!

        expect(described_class.parse(document, json_api_resource)).to eq(
          blargh_ids: %w(42 11)
        )
      end
      it 'only returns known relationship collections' do
        foo_json_api_resource_class = Class.new(FunWithJsonApi::ActiveModelResource)
        json_api_resource = Class.new(FunWithJsonApi::ActiveModelResource) do
          has_many :foos, foo_json_api_resource_class
        end.create

        document = {
          data: {
            relationships: {
              foos: {
                data: [{ id: '42', type: 'foos' }]
              },
              blargh: {
                data: [{ id: '24', type: 'blarghs' }]
              }
            }
          }
        }.deep_stringify_keys!

        expect(described_class.parse(document, json_api_resource)).to eq(
          foo_ids: ['42']
        )
      end
    end

    describe 'parser exceptions' do
      it 'handles an invalid /data value' do
        json_api_resource = Class.new(FunWithJsonApi::ActiveModelResource).create
        [
          nil,
          {},
          {
            'data' => nil
          }
        ].each do |document|
          expect do
            described_class.parse(document, json_api_resource)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidDocument) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_document'
            expect(payload.title).to eq I18n.t('fun_with_json_api.exceptions.invalid_document')
            expect(payload.pointer).to eq '/data'
            expect(payload.detail).to be_kind_of(String)
          end
        end
      end
      it 'handles an invalid /data/attributes value' do
        json_api_resource = Class.new(FunWithJsonApi::ActiveModelResource).create
        [
          {
            'data' => { 'attributes' => [] }
          }
        ].each do |document|
          expect do
            described_class.parse(document, json_api_resource)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidDocument) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_document'
            expect(payload.title).to eq I18n.t('fun_with_json_api.exceptions.invalid_document')
            expect(payload.pointer).to eq '/data/attributes'
            expect(payload.detail).to be_kind_of(String)
          end
        end
      end
      it 'handles an invalid /data/relationships value' do
        json_api_resource = Class.new(FunWithJsonApi::ActiveModelResource).create
        [
          {
            'data' => { 'relationships' => [] }
          }
        ].each do |document|
          expect do
            described_class.parse(document, json_api_resource)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidDocument) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_document'
            expect(payload.title).to eq I18n.t('fun_with_json_api.exceptions.invalid_document')
            expect(payload.pointer).to eq '/data/relationships'
            expect(payload.detail).to be_kind_of(String)
          end
        end
      end
      it 'handles an invalid relationship value' do
        json_api_resource = Class.new(FunWithJsonApi::ActiveModelResource).create
        [
          {
            'data' => {
              'relationships' => { 'rel' => nil }
            }
          }, {
            'data' => {
              'relationships' => { 'rel' => {} }
            }
          }
        ].each do |document|
          expect do
            described_class.parse(document, json_api_resource)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidDocument) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_document'
            expect(payload.title).to eq I18n.t('fun_with_json_api.exceptions.invalid_document')
            expect(payload.pointer).to eq '/data/relationships/rel'
            expect(payload.detail).to be_kind_of(String)
          end
        end
      end
    end
  end
end
