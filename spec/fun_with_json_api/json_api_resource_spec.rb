require 'spec_helper'

# Returns a FunWithJsonApi::JsonApiResource class with an attribute
#
# Equivalent of:
# ```
# class ExampleApiResource < FunWithJsonApi::JsonApiResource
#   attribute #{attribute}, #{attribute_options}
# end
def json_api_resource_class_with_attribute(attribute, attribute_options = {})
  Class.new(FunWithJsonApi::JsonApiResource) do
    attribute attribute, attribute_options
  end
end

def json_api_resource_class_with_relationship(relationship, relationship_type, relationship_options = {})
  relationship_json_api_resource = Class.new(FunWithJsonApi::JsonApiResource) do
    type(relationship_type)
  end

  Class.new(FunWithJsonApi::JsonApiResource) do
    belongs_to relationship, relationship_json_api_resource, relationship_options
  end
end

# Returns an instance of a FunWithJsonApi::JsonApiResource with an attribute with an assigned value
#
# Equivalent of:
# ```
# class ExampleApiResource < FunWithJsonApi::JsonApiResource
#   attribute #{attribute}, #{attribute_options}
# end
# ExampleApiResource.create
# ~~~
def json_api_resource_with_attribute(attribute, attribute_options = {})
  json_api_resource_class_with_attribute(attribute, attribute_options).create
end

describe FunWithJsonApi::JsonApiResource do
  describe '.id_param' do
    context 'with no arguments' do
      it 'sets id_param to id for all new json_api_resource instances' do
        instance = Class.new(described_class).create
        expect(instance.id_param).to eq :id
        expect(instance.attributes.size).to eq 0
      end
    end
    context 'with a name argument' do
      it 'adds an aliased id attribute for all new json_api_resource instances' do
        instance = Class.new(described_class) do
          id_param :code
        end.create
        expect(instance.id_param).to eq :code
        expect(instance.attributes.size).to eq 0
      end
      it 'converts the name parameter to a symbol' do
        instance = Class.new(described_class) do
          id_param 'code'
        end.create
        expect(instance.id_param).to eq :code
        expect(instance.attributes.size).to eq 0
      end
    end
    context 'with a format argument' do
      it 'adds an id attribute with format to all new json_api_resource instances' do
        instance = Class.new(described_class) do
          id_param format: :integer
        end.create
        expect(instance.id_param).to eq :id
        expect(instance.attributes.size).to eq 1

        attribute = instance.attributes.first
        expect(attribute).to be_kind_of(FunWithJsonApi::Attributes::IntegerAttribute)
        expect(attribute.name).to eq :id
        expect(attribute.as).to eq :id
      end
    end
    context 'with a name and format argument' do
      it 'adds an aliased id attribute with format to all new json_api_resource instances' do
        instance = Class.new(described_class) do
          id_param :code, format: :uuid_v4
        end.create
        expect(instance.id_param).to eq :code
        expect(instance.attributes.size).to eq 1

        attribute = instance.attributes.first
        expect(attribute).to be_kind_of(FunWithJsonApi::Attributes::UuidV4Attribute)
        expect(attribute.name).to eq :id
        expect(attribute.as).to eq :code
      end
    end
  end

  describe '#decode_{attribute}' do
    context 'with an alias value' do
      it 'defines a decode method from the name value' do
        json_api_resource = json_api_resource_with_attribute(:original_key, as: :assigned_key)
        expect(json_api_resource.decode_original_key('Foo Bar')).to eq 'Foo Bar'
        expect(json_api_resource).not_to respond_to(:decode_assigned_key)
      end
    end

    context 'with no format argument (string)' do
      it 'allows a String value' do
        json_api_resource = json_api_resource_with_attribute(:example)
        expect(json_api_resource.decode_example('Foo Bar')).to eq 'Foo Bar'
      end
      it 'allows a nil value' do
        json_api_resource = json_api_resource_with_attribute(:example)
        expect(json_api_resource.decode_example(nil)).to be nil
      end
      it 'raises an InvalidAttribute error an for non string value' do
        json_api_resource = json_api_resource_with_attribute(:example)
        [1, true, false, [], {}].each do |value|
          expect do
            json_api_resource.decode_example(value)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidAttribute) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_attribute'
            expect(payload.title).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_attribute')
            )
            expect(payload.detail).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_string_attribute')
            )
            expect(payload.pointer).to eq '/data/attributes/example'
          end
        end
      end
    end

    context 'with a boolean format' do
      it 'allows a Boolean.TRUE value' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :boolean)
        expect(json_api_resource.decode_example(true)).to eq true
      end
      it 'allows a Boolean.FALSE value' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :boolean)
        expect(json_api_resource.decode_example(false)).to eq false
      end
      it 'allows a nil value' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :boolean)
        expect(json_api_resource.decode_example(nil)).to be nil
      end
      it 'raises an InvalidAttribute error an for invalid boolean values' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :boolean)
        ['true', 'True', 'TRUE', 1, 'false', 'False', 'FALSE', 0].each do |value|
          expect do
            json_api_resource.decode_example(value)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidAttribute) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_attribute'
            expect(payload.title).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_attribute')
            )
            expect(payload.detail).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_boolean_attribute')
            )
            expect(payload.pointer).to eq '/data/attributes/example'
          end
        end
      end
    end

    context 'with a date format' do
      it 'allows a "YYYY-MM-DD" formatted date String' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :date)
        expect(json_api_resource.decode_example('2016-03-12')).to eq Date.new(2016, 03, 12)
      end
      it 'allows a nil value' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :date)
        expect(json_api_resource.decode_example(nil)).to be nil
      end
      it 'raises an InvalidAttribute error an for invalid date value' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :date)
        ['2016-12', 'Last Wednesday', 'April'].each do |value|
          expect do
            json_api_resource.decode_example(value)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidAttribute) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_attribute'
            expect(payload.title).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_attribute')
            )
            expect(payload.detail).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_date_attribute')
            )
            expect(payload.pointer).to eq '/data/attributes/example'
          end
        end
      end
    end

    context 'with a datetime format' do
      it 'allows a ISO 8601 formatted values' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :datetime)
        [
          '2016-03-11T03:45:40+00:00',
          '2016-03-11T13:45:40+10:00',
          '2016-03-11T03:45:40Z',
          '20160311T034540Z'
        ].each do |timestamp|
          expect(json_api_resource.decode_example(timestamp)).to eq(
            DateTime.new(2016, 03, 11, 3, 45, 40, 0)
          )
        end
      end
      it 'allows a nil value' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :datetime)
        expect(json_api_resource.decode_example(nil)).to be nil
      end
      it 'raises an InvalidAttribute error an for invalid date value' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :datetime)
        [
          'Last Wednesday',
          'April'
        ].each do |value|
          expect do
            json_api_resource.decode_example(value)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidAttribute) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_attribute'
            expect(payload.title).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_attribute')
            )
            expect(payload.detail).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_datetime_attribute')
            )
            expect(payload.pointer).to eq '/data/attributes/example'
          end
        end
      end
    end

    context 'with a decimal format' do
      it 'allows integers' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :decimal)
        expect(json_api_resource.decode_example(12)).to eq BigDecimal.new('12')
      end
      it 'allows floats' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :decimal)
        expect(json_api_resource.decode_example(12.34)).to eq BigDecimal.new('12.34')
      end
      it 'allows integer numbers as strings' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :decimal)
        expect(json_api_resource.decode_example('12')).to eq BigDecimal.new('12')
      end
      it 'allows floating point numbers as strings' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :decimal)
        expect(json_api_resource.decode_example('12.30')).to eq BigDecimal.new('12.30')
      end
      it 'allows a nil value' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :decimal)
        expect(json_api_resource.decode_example(nil)).to be nil
      end
      it 'raises an InvalidAttribute error an for invalid decimal value' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :decimal)
        [
          'twelve',
          '-',
          'abc'
        ].each do |value|
          expect do
            json_api_resource.decode_example(value)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidAttribute) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_attribute'
            expect(payload.title).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_attribute')
            )
            expect(payload.detail).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_decimal_attribute')
            )
            expect(payload.pointer).to eq '/data/attributes/example'
          end
        end
      end
    end

    context 'with a float format' do
      it 'allows floats' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :float)
        expect(json_api_resource.decode_example(12.34)).to eq 12.34
      end
      it 'allows float numbers as strings' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :float)
        expect(json_api_resource.decode_example('12.34')).to eq 12.34
      end
      it 'allows integer numbers as strings' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :float)
        expect(json_api_resource.decode_example('12')).to eq 12.0
      end
      it 'allows a nil value' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :float)
        expect(json_api_resource.decode_example(nil)).to be nil
      end
      it 'raises an InvalidAttribute error an for invalid float value' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :float)
        [
          'twelve',
          '-',
          'abc'
        ].each do |value|
          expect do
            json_api_resource.decode_example(value)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidAttribute) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_attribute'
            expect(payload.title).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_attribute')
            )
            expect(payload.detail).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_float_attribute')
            )
            expect(payload.pointer).to eq '/data/attributes/example'
          end
        end
      end
    end

    context 'with a integer format' do
      it 'allows integer numbers as strings' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :integer)
        expect(json_api_resource.decode_example('12')).to eq BigDecimal.new('12')
      end
      it 'allows a nil value' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :integer)
        expect(json_api_resource.decode_example(nil)).to be nil
      end
      it 'raises an InvalidAttribute error an for invalid integer value' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :integer)
        [
          12.0,
          '12.0',
          'twelve',
          '-',
          'abc'
        ].each do |value|
          expect do
            json_api_resource.decode_example(value)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidAttribute) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_attribute'
            expect(payload.title).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_attribute')
            )
            expect(payload.detail).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_integer_attribute')
            )
            expect(payload.pointer).to eq '/data/attributes/example'
          end
        end
      end
    end

    context 'with a uuid_v4 format' do
      it 'allows uuid_v4 numbers as strings' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :uuid_v4)
        expect(json_api_resource.decode_example('f47ac10b-58cc-4372-a567-0e02b2c3d479')).to eq(
          'f47ac10b-58cc-4372-a567-0e02b2c3d479'
        )
      end
      it 'allows a nil value' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :uuid_v4)
        expect(json_api_resource.decode_example(nil)).to be nil
      end
      it 'raises an InvalidAttribute error an for invalid uuid_v4 value' do
        json_api_resource = json_api_resource_with_attribute(:example, format: :uuid_v4)
        [
          'abc',
          12.0,
          '12.0',
          '6ba7b810-9dad-11d1-80b4-00c04fd430c8', # RFC 4122 version 3
          'f47ac10b58cc4372a5670e02b2c3d479' # uuid without dashes
        ].each do |value|
          expect do
            json_api_resource.decode_example(value)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidAttribute) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_attribute'
            expect(payload.title).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_attribute')
            )
            expect(payload.detail).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_uuid_v4_attribute')
            )
            expect(payload.pointer).to eq '/data/attributes/example'
          end
        end
      end
    end

    it 'raises an ArgumentError with an unknown format' do
      expect do
        json_api_resource_class_with_attribute(:example, format: :blarg)
      end.to raise_error(ArgumentError)
    end

    it 'raises an ArgumentError with a blank attribute name' do
      expect do
        json_api_resource_class_with_attribute('', format: :string)
      end.to raise_error(ArgumentError)
    end
  end
end
