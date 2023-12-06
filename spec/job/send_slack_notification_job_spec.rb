# frozen_string_literal: true

describe SendSlackNotificationJob do
  describe '#perform' do
    it 'enqueues the job' do
      message = 'test message'
      described_class.perform_async(message)
      expect(described_class).to have_enqueued_sidekiq_job.with(message)
    end
  end
end
