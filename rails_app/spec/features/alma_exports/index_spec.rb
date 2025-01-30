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
      let(:additional_values) { { started_at: Time.current, job_identifier: '1234' } }

      it 'displays started_at' do
        within('.started-at') do
          expect(page).to have_text(alma_export.started_at.to_fs(:display))
        end
      end

      it 'displays job_identifier' do
        within('.job-id') do
          expect(page).to have_text(alma_export.job_identifier)
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

  context 'when filtering alma exports by status' do
    let!(:alma_export) { create(:alma_export) }

    before do
      create(:alma_export, status: 'completed')
      visit alma_exports_path
    end

    it 'filters by status' do
      select 'Completed', from: 'Status'
      click_on 'Filter'
      expect(page).to have_css('.alma-export-row', count: 1)
      within('th.id') { expect(page).not_to have_text alma_export.id }
    end
  end

  context 'when sorting alma exports by started_at' do
    let!(:alma_export) { create(:alma_export, started_at: 2.hours.ago) }
    let!(:other_alma_export) { create(:alma_export, started_at: 1.hour.ago) }

    before do
      visit alma_exports_path
    end

    it 'sorts by started_at ascending' do
      select 'Started At', from: 'Sort by'
      select 'Ascending', from: 'Order'
      click_on 'Filter'
      expect(first('.alma-export-row')).to have_text(alma_export.id)
    end

    it 'sorts by started_at descending' do
      select 'Started At', from: 'Sort by'
      select 'Descending', from: 'Order'
      click_on 'Filter'
      expect(first('.alma-export-row')).to have_text(other_alma_export.id)
    end
  end

  context 'when sorting alma exports by completed_at' do
    let!(:alma_export) { create(:alma_export, completed_at: 2.hours.ago) }
    let!(:other_alma_export) { create(:alma_export, completed_at: 1.hour.ago) }

    before do
      visit alma_exports_path
    end

    it 'sorts by completed_at ascending' do
      select 'Completed At', from: 'Sort by'
      select 'Ascending', from: 'Order'
      click_on 'Filter'
      expect(first('.alma-export-row')).to have_text(alma_export.id)
    end

    it 'sorts by completed_at descending' do
      select 'Completed At', from: 'Sort by'
      select 'Descending', from: 'Order'
      click_on 'Filter'
      expect(first('.alma-export-row')).to have_text(other_alma_export.id)
    end
  end
end
