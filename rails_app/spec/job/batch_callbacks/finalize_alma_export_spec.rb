# frozen_string_literal: true

describe BatchCallbacks::FinalizeAlmaExport do
  describe '#on_success' do
    let(:collections) { %w[collection1 collection2] }
    let(:alma_export) { create(:alma_export, :with_files_all_completed, target_collections: collections) }

    include_context 'with solr collections supporting commits'

    before { described_class.new.on_success(nil, alma_export.id) }

    it 'marks the AlmaExport as completed' do
      alma_export.reload
      expect(alma_export.status).to eq Statuses::COMPLETED
      expect(alma_export.completed_at).to be_present
    end
  end


  describe '#on_complete' do
    let(:alma_export) { create(:alma_export) }
    let(:mock_status) { double(Sidekiq::Batch::Status, failure_jids: []) }

    before { described_class.new.on_complete(mock_status, alma_export.id) }

    it 'sends a Slack notification that all jobs have executed' do
      expect(SendSlackNotificationJob).to have_enqueued_sidekiq_job(
        a_string_including(alma_export.id.to_s)
      )
    end

    context 'when there are job failures' do
      let(:failure_jids) { %w[abc123 def456] }
      let(:mock_status) { double(Sidekiq::Batch::Status, failure_jids: failure_jids) }

      it 'sends a Slack notification about the failures' do
        expect(SendSlackNotificationJob).to have_enqueued_sidekiq_job(
          a_string_including(alma_export.id.to_s, *failure_jids)
        )
      end
    end
  end
end
