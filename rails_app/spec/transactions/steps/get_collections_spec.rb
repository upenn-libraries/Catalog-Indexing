# frozen_string_literal: true

describe Steps::GetCollections do
  let(:step) { described_class.new }
  let(:result) { step.call(**args) }
  let(:args) { {} }

  describe '#call' do
    context 'with collection specified in args' do
      let(:args) { { collections: collections } }
      let(:collections) { %w[c1 c2] }

      it 'prefers the argument collection over any ConfigItem value' do
        expect(result).to be_success
        expect(result.success[:collections]).to eq collections
      end
    end

    context 'with no args and collections specified in the ConfigItem value' do
      let(:collections) { %w[c1 c2] }

      before do
        allow(ConfigItem).to receive(:value_for).with(:webhook_target_collections).and_return(collections)
      end

      it 'returns collections value from the ConfigItem' do
        expect(result).to be_success
        expect(result.success[:collections]).to eq collections
      end
    end

    context 'with no collections defined anywhere' do
      before do
        allow(ConfigItem).to receive(:value_for).with(:webhook_target_collections).and_return([])
      end

      it 'returns a Failure monad' do
        expect(result).to be_failure
      end
    end
  end
end
