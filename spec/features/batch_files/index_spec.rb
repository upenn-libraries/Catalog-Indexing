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

    it 'displays IDs' do
      within(first('th.id')) { expect(page).to have_link(alma_export.batch_files.first.id) }
    end

    # displays path
    # displays status
    # displays errors messages (when none)
    # displays errors messages (when populated)
    # displays started_at
    # displays completed_at
    # displays created_at
    # displays updated_at
  end
end
