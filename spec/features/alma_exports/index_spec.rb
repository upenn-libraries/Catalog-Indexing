# frozen_string_literal: true

describe 'Alma Export Show Page' do
  let(:user) { create(:user) }

  before { sign_in user }

  context 'when viewing Alma Exports' do
    let(:alma_export) { create(:alma_export_with_files) }

    before { visit alma_exports_path }

    it 'lists all Alma Exports' do
      expect(page).to have_css('tr.alma-export', count: AlmaExport.count)
    end
  end
end
