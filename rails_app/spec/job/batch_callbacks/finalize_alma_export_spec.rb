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
end
