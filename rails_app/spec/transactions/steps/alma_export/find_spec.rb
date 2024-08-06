# frozen_string_literal: true

describe Steps::AlmaExport::Find do
  let(:result) { described_class.new.call(alma_export_id: alma_export_id) }

  context 'with an existing AlmaExport' do
    context 'with a "PENDING" state' do
      let(:alma_export) { create(:alma_export, :pending) }
      let(:alma_export_id) { alma_export.id }

      it 'returns success and the alma_export' do
        expect(result).to be_success
        expect(result.success[:alma_export]).to eq alma_export
      end
    end

    context 'with an "IN PROGRESS" state' do
      let(:alma_export) { create(:alma_export, :in_progress) }
      let(:alma_export_id) { alma_export.id }
      let(:error_message) { "AlmaExport with ID #{alma_export_id} is in in_progress. It must be in 'pending' state." }

      it 'returns a failure with appropriate message' do
        expect(result).to be_failure
        expect(result.failure[:message]).to include error_message
      end

      it 'updates the AlmaExport with failure message' do
        result
        expect(alma_export.reload.error_messages.first).to include error_message
        expect(alma_export.status).to eq Statuses::FAILED
      end
    end
  end

  context 'with an invalid AlmaExport identifier' do
    let(:alma_export_id) { 'invalid' }

    it 'returns a failure with appropriate message' do
      expect(result).to be_failure
      expect(result.failure[:message]).to include 'does not exist'
    end
  end
end
