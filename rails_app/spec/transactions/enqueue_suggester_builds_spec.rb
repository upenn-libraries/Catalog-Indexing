# frozen_string_literal: true

describe EnqueueSuggesterBuilds do
  let(:transaction) { described_class.new }
  let(:outcome) { transaction.call(alma_export: alma_export) }

  before { allow(ConfigItem).to receive(:value_for).with(config_item).and_return(config_value) }

  context 'with a full AlmaExport' do
    let(:alma_export) { create(:alma_export, :full) }
    let(:config_item) { :build_suggesters_after_full }

    context 'with the build_suggesters_after_full ConfigItem set to true' do
      let(:config_value) { true }

      it 'returns a Success monad with message that the job was enqueued' do
        expect(outcome).to be_success
        expect(outcome.success[:message]).to eq 'Suggester builds enqueued.'
      end
    end

    context 'with the build_suggesters_after_full ConfigItem set to false' do
      let(:config_value) { false }

      it 'returns a Success monad with message that the job was not enqueued' do
        expect(outcome).to be_success
        expect(outcome.success[:message]).to eq 'Suggester builds disabled.'
      end
    end
  end

  context 'with an incremental AlmaExport' do
    let(:alma_export) { create(:alma_export, :incremental) }
    let(:config_item) { :build_suggesters_after_incremental }

    context 'with the build_suggesters_after_incremental ConfigItem set to true' do
      let(:config_value) { true }

      it 'returns a Success monad with message that the job was enqueued' do
        expect(outcome).to be_success
        expect(outcome.success[:message]).to eq 'Suggester builds enqueued.'
      end
    end

    context 'with the build_suggesters_after_incremental ConfigItem set to false' do
      let(:config_value) { false }

      it 'returns a Success monad with message that the job was not enqueued' do
        expect(outcome).to be_success
        expect(outcome.success[:message]).to eq 'Suggester builds disabled.'
      end
    end
  end
end
