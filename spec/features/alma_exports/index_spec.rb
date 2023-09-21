# frozen_string_literal: true

describe 'Alma Export Index Page' do
  let(:user) { create(:user) }

  before { sign_in user }

  context 'when viewing Alma Exports' do
    let!(:alma_export) { create(:alma_export, **additional_values) }
    let(:alma_export_row) { ".alma-export-row.row-id-#{alma_export.id}" }
    let(:additional_values) { {} }

    before { visit alma_exports_path }

    it 'lists all Alma Exports' do
      expect(page).to have_css('.alma-export-row', count: AlmaExport.count)
    end

    it 'displays IDs' do
      within(alma_export_row) do
        expect(find('.id')).to have_link(alma_export.id.to_s)
      end
    end

    it 'displays Not Started when started_at is nil' do
      within(alma_export_row) do
        expect(find('.started-at')).to have_text('Not Started')
      end
    end

    context 'with additional values' do
      let(:additional_values) { { started_at: Time.current } }

      it 'displays started_at' do
        within('.started-at') do
          expect(page).to have_text(alma_export.started_at)
        end
      end
    end

    it 'displays status' do
      within('.alma-export-row') { expect(find('.status')).to have_text(alma_export.status.capitalize) }
    end

    it 'displays batch file count' do
      within('.alma-export-row') { expect(find('.batch-files')).to have_text(alma_export.batch_files.count) }
    end
  end
end
