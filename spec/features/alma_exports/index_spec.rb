# frozen_string_literal: true

describe 'Alma Export Index Page' do
  let(:user) { create(:user) }

  before { sign_in user }

  context 'when viewing Alma Exports' do
    let(:alma_export) { create(:alma_export_with_files) }

    before { visit alma_exports_path }

    it 'lists all Alma Exports' do
      expect(page).to have_css('tr.alma-export', count: AlmaExport.count)
    end

    it 'shows IDs' do
      expect(page).to have_css('th.id', count: AlmaExport.count)
    end

    it 'shows started_at' do
      expect(page).to have_css('td.started-at', count: AlmaExport.count)
    end

    it 'shows status' do
      expect(page).to have_css('td.status', count: AlmaExport.count)
    end

    it 'shows batch file count' do
      expect(page).to have_css('td.batch-files', count: AlmaExport.count)
    end
  end
end
