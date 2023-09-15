# frozen_string_literal: true

describe 'Alma Export Index Page' do
  let(:user) { create(:user) }

  before { sign_in user }

  context 'when viewing Alma Exports' do
    let!(:alma_export) { create(:alma_export) }

    before { visit alma_exports_path }

    it 'lists all Alma Exports' do
      expect(page).to have_css('tr.alma-export', count: AlmaExport.count)
    end

    it 'shows IDs' do
      within('th.id') { expect(page).to have_link(alma_export.id) }
    end

    it 'shows Not Stared when AlmaExport started_at is nil' do
      within('td.started-at') { expect(page).to have_text('Not Started') }
    end

    # TODO: implement test for checking started_at when it is populated

    it 'shows status' do
      within('td.status') { expect(page).to have_text(alma_export.status.capitalize) }
    end

    it 'shows batch file count' do
      within('td.batch-files') { expect(page).to have_text(alma_export.batch_files.count) }
    end
  end
end
