# frozen_string_literal: true

describe 'Batch Files Index Page' do
  let(:user) { create(:user) }

  before { sign_in user }

  context 'when viewing batch files' do
    let(:alma_export) { create(:alma_export) }
    let!(:batch_file) { create(:batch_file, alma_export: alma_export, **additional_values) }
    let(:batch_file_row) { ".batch-file-row.row-id-#{batch_file.id}" }
    let(:additional_values) { {} }

    before { visit alma_export_batch_files_path(alma_export) }

    it 'displays ID of alma export' do
      expect(page).to have_text("Batch Files for Alma Export: #{alma_export.id}")
    end

    it 'lists all batch files' do
      expect(page).to have_css('.batch-file-row', count: alma_export.batch_files.count)
    end

    it 'displays IDs' do
      within(batch_file_row) do
        expect(find('.id')).to have_link(batch_file.id.to_s)
      end
    end

    it 'displays path' do
      within(batch_file_row) do
        expect(find('.path')).to have_text(batch_file.path)
      end
    end

    it 'displays status' do
      within(batch_file_row) do
        expect(find('.status')).to have_text(batch_file.status.capitalize)
      end
    end

    it 'displays errors' do
      within(batch_file_row) do
        expect(find('.errors')).to have_text(batch_file.error_messages.count)
      end
    end

    context 'with additional values' do
      let(:additional_values) do
        {
          started_at: 1.hour.ago,
          completed_at: Time.current
        }
      end

      it 'displays started_at' do
        within(batch_file_row) do
          expect(find('.started-at')).to have_text(batch_file.started_at)
        end
      end

      it 'displays completed_at' do
        within(batch_file_row) do
          expect(find('.completed-at')).to have_text(batch_file.completed_at)
        end
      end
    end

    it 'displays "Not Started" when batch file started_at is nil' do
      within(batch_file_row) do
        expect(find('.started-at')).to have_text('Not Started')
      end
    end

    it 'displays "Not Completed" when batch file started_at is nil' do
      within(batch_file_row) do
        expect(find('.completed-at')).to have_text('Not Completed')
      end
    end

    it 'displays created_at' do
      within(batch_file_row) do
        expect(find('.created-at')).to have_text(batch_file.created_at)
      end
    end

    it 'displays updated_at' do
      within(batch_file_row) do
        expect(find('.updated-at')).to have_text(batch_file.updated_at)
      end
    end
  end

  context 'when searching batch files' do
    let(:alma_export) { create(:alma_export) }

    before do
      create(:batch_file, alma_export: alma_export, path: 'path/to/file')
      create(:batch_file, alma_export: alma_export, path: 'second/batch/file')
      visit alma_export_batch_files_path(alma_export)
    end

    it 'returns the result with the query in the path' do
      fill_in 'Search', with: 'path'
      click_on 'Filter'
      expect(page).to have_css('.batch-file-row'), count: 1
      expect(find('.batch-file-row')).to have_text 'path/to/file'
    end
  end

  context 'when filtering batch files by status' do
    let(:alma_export) { create(:alma_export) }

    before do
      create(:batch_file, alma_export: alma_export, status: 'pending')
      create(:batch_file, alma_export: alma_export, status: 'completed')
      visit alma_export_batch_files_path(alma_export)
    end

    it 'filters by status' do
      select 'Completed', from: 'Status'
      click_on 'Filter'
      expect(page).to have_css('.batch-file-row'), count: 1
      expect(find('.batch-file-row')).to have_text 'Completed'
    end
  end

  context 'when sorting batch files by started_at' do
    let(:alma_export) { create(:alma_export) }
    let!(:batch_file) { create(:batch_file, alma_export: alma_export, started_at: 2.hours.ago) }
    let!(:other_batch_file) { create(:batch_file, alma_export: alma_export, started_at: 1.hour.ago) }

    before do
      visit alma_export_batch_files_path(alma_export)
    end

    it 'sorts by started_at ascending' do
      select 'Started At', from: 'Sort by'
      select 'Ascending', from: 'Order'
      click_on 'Filter'
      expect(first('.batch-file-row')).to have_text(batch_file.id)
    end

    it 'sorts by started_at descending' do
      select 'Started At', from: 'Sort by'
      select 'Descending', from: 'Order'
      click_on 'Filter'
      expect(first('.batch-file-row')).to have_text(other_batch_file.id)
    end
  end

  context 'when sorting batch files by completed_at' do
    let(:alma_export) { create(:alma_export) }
    let!(:batch_file) { create(:batch_file, alma_export: alma_export, completed_at: 2.hours.ago) }
    let!(:other_batch_file) { create(:batch_file, alma_export: alma_export, completed_at: 1.hour.ago) }

    before do
      visit alma_export_batch_files_path(alma_export)
    end

    it 'sorts by completed_at ascending' do
      select 'Completed At', from: 'Sort by'
      select 'Ascending', from: 'Order'
      click_on 'Filter'
      expect(first('.batch-file-row')).to have_text(batch_file.id)
    end

    it 'sorts by completed_at descending' do
      select 'Completed At', from: 'Sort by'
      select 'Descending', from: 'Order'
      click_on 'Filter'
      expect(first('.batch-file-row')).to have_text(other_batch_file.id)
    end
  end
end
