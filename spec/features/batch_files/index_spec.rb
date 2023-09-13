# frozen_string_literal: true

describe 'Batch Files Index Page' do
  let(:user) { create(:user) }

  before { sign_in user }

  context 'when viewing batch files' do
    let(:alma_export) { create(:alma_export_with_files) }

    before { visit alma_export_batch_files_path(alma_export) }

    it 'displays ID of alma export' do
      expect(page).to have_text("Batch Files for Alma Export: #{alma_export.id}")
    end

    it 'lists all batch files' do
      expect(page).to have_css('tr.batch-file', count: alma_export.batch_files.count)
    end
  end
end
