require 'spec_helper'

describe FunWithJsonApi::Attributes::Base64Attribute do
  let(:attribute_name) { Faker::Lorem.word.downcase }
  subject(:attribute) { described_class.new(attribute_name) }

  describe '.call' do
    it 'converts a nil string to nil' do
      expect(attribute.call(nil)).to eq nil
    end

    it 'decodes a String using Base64.decode64' do
      decoded = 'FunWithJsonApi'
      encoded = Base64.encode64(decoded)

      expect(attribute.call(encoded)).to eq decoded
    end

    it 'raises an InvalidAttribute error for non string value' do
      [123, true, {}, []].each do |value|
        expect do
          attribute.call(value)
        end.to raise_error(FunWithJsonApi::Exceptions::InvalidAttribute) do |e|
          expect(e.payload.size).to eq 1

          payload = e.payload.first
          expect(payload.status).to eq '400'
          expect(payload.code).to eq 'invalid_attribute'
          expect(payload.title).to eq(
            I18n.t('fun_with_json_api.exceptions.invalid_attribute')
          )
          expect(payload.detail).to eq(
            I18n.t('fun_with_json_api.exceptions.invalid_base64_attribute')
          )
          expect(payload.pointer).to eq "/data/attributes/#{attribute_name}"
        end
      end
    end
  end
end
