require 'spec_helper'

describe FunWithJsonApi::DeserializerClassMethods do
  describe '.belongs_to' do
    it 'adds a Relationship attribute' do
      foos_deserializer_class = Class.new(FunWithJsonApi::Deserializer) do
        attribute :blargh
        has_many :foos, -> { foos_deserializer_class }
      end
      deserializer_class = Class.new(FunWithJsonApi::Deserializer) do
        belongs_to :foo, -> { foos_deserializer_class }
      end

      deserializer = deserializer_class.create

      relationship = deserializer.relationships.last
      expect(relationship).to be_kind_of(FunWithJsonApi::Attributes::Relationship)

      expect(relationship.name).to eq :foo
      expect(relationship.as).to eq :foo
      expect(relationship.deserializer).to be_kind_of(foos_deserializer_class)

      expect(relationship.deserializer.attributes).to match(
        [kind_of(FunWithJsonApi::Attributes::StringAttribute)]
      )
      expect(relationship.deserializer.relationships).to eq []
    end
  end

  describe '.has_many' do
    it 'adds a RelationshipCollection attribute' do
      foos_deserializer_class = Class.new(FunWithJsonApi::Deserializer) do
        attribute :blargh
        has_many :foos, -> { foos_deserializer_class }
      end
      deserializer_class = Class.new(FunWithJsonApi::Deserializer) do
        has_many :foos, -> { foos_deserializer_class }
      end

      deserializer = deserializer_class.create

      relationship = deserializer.relationships.last
      expect(relationship).to be_kind_of(FunWithJsonApi::Attributes::RelationshipCollection)

      expect(relationship.name).to eq :foos
      expect(relationship.as).to eq :foos
      expect(relationship.param_value).to eq :foo_ids
      expect(relationship.deserializer).to be_kind_of(foos_deserializer_class)

      expect(relationship.deserializer.attributes).to match(
        [kind_of(FunWithJsonApi::Attributes::StringAttribute)]
      )
      expect(relationship.deserializer.relationships).to eq []
    end
  end
end
