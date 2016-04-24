require 'spec_helper'

describe FunWithJsonApi::ResourceDSLMethods do
  describe '.belongs_to' do
    it 'adds a Relationship attribute' do
      foos_json_api_resource_class = Class.new(FunWithJsonApi::ActiveModelResource) do
        attribute :blargh
        has_many :foos, -> { foos_json_api_resource_class }
      end
      json_api_resource_class = Class.new(FunWithJsonApi::ActiveModelResource) do
        belongs_to :foo, -> { foos_json_api_resource_class }
      end

      json_api_resource = json_api_resource_class.create

      relationship = json_api_resource.relationships.last
      expect(relationship).to be_kind_of(FunWithJsonApi::Attributes::Relationship)

      expect(relationship.name).to eq :foo
      expect(relationship.as).to eq :foo
      expect(relationship.json_api_resource).to be_kind_of(foos_json_api_resource_class)

      expect(relationship.json_api_resource.attributes).to match(
        [kind_of(FunWithJsonApi::Attributes::StringAttribute)]
      )
      expect(relationship.json_api_resource.relationships).to eq []
    end
  end

  describe '.has_many' do
    it 'adds a RelationshipCollection attribute' do
      foos_json_api_resource_class = Class.new(FunWithJsonApi::ActiveModelResource) do
        attribute :blargh
        has_many :foos, -> { foos_json_api_resource_class }
      end
      json_api_resource_class = Class.new(FunWithJsonApi::ActiveModelResource) do
        has_many :foos, -> { foos_json_api_resource_class }
      end

      json_api_resource = json_api_resource_class.create

      relationship = json_api_resource.relationships.last
      expect(relationship).to be_kind_of(FunWithJsonApi::Attributes::RelationshipCollection)

      expect(relationship.name).to eq :foos
      expect(relationship.as).to eq :foos
      expect(relationship.param_value).to eq :foo_ids
      expect(relationship.json_api_resource).to be_kind_of(foos_json_api_resource_class)

      expect(relationship.json_api_resource.attributes).to match(
        [kind_of(FunWithJsonApi::Attributes::StringAttribute)]
      )
      expect(relationship.json_api_resource.relationships).to eq []
    end
  end
end
