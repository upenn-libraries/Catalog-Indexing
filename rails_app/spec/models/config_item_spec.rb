# frozen_string_literal: true

describe ConfigItem do
  describe '.value_for' do
    let(:config_item) { create(:config_item, :boolean) }
    let(:details) { { config_item.name.to_sym => { default: !config_item.value } } }

    it 'returns the value for the names config_item' do
      expect(described_class.value_for(config_item.name, details: details)).to eq config_item.value
    end

    it 'raises and exception if a config_item is not found by that name' do
      expect {
        described_class.value_for(:nonexistent, details: details)
      }.to raise_error ArgumentError
    end
  end
end
