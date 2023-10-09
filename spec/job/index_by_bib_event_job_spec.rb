# frozen_string_literal: true

describe IndexByBibEventJob do
  include FixtureHelpers

  let(:sample_mmsid) { '9979201969103681' }
  let(:marcxml) { marc_fixture sample_mmsid }
  let(:transaction) { IndexByBibEvent.new }

  describe '#perform' do
    it 'enqueues the job' do
      described_class.perform_async(marcxml)
      expect(described_class).to have_enqueued_sidekiq_job.with(marcxml)
    end

    it 'calls the transaction with the correct argument' do
      allow(IndexByBibEvent).to receive(:new).and_return(transaction)
      allow(transaction).to receive(:call)
      described_class.perform_inline(marcxml)
      expect(transaction).to have_received(:call).with(docs: marcxml)
    end
  end
end
