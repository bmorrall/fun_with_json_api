require 'spec_helper'

describe FunWithJsonApi::Configuration do
  describe '#force_render_encode_errors_as_json_api?' do
    it 'has a writer method' do
      instance = described_class.new

      instance.force_render_encode_errors_as_json_api = true
      expect(instance.force_render_encode_errors_as_json_api?).to be true

      instance.force_render_encode_errors_as_json_api = false
      expect(instance.force_render_encode_errors_as_json_api?).to be false
    end

    it 'defaults to false by default' do
      expect(described_class.new.force_render_encode_errors_as_json_api?).to be false
    end
  end
end
