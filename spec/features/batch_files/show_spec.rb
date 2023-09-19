# frozen_string_literal: true

describe 'Batch Files Show Page' do
  let(:user) { create(:user) }

  before { sign_in user }

  context 'when viewing batch files' do
    let(:alma_export) { create(:alma_export) }
    let(:batch_file) { create(:batch_file, alma_export: alma_export, **additional_values) }
    let(:additional_values) { {} }

    before { visit alma_export_batch_file_path(alma_export, batch_file) }

    it 'shows parent alma export' do
      expect(page).to have_text("Belongs to Alma Export: #{alma_export.id}")
    end

    it 'displays ID' do
      within('.batch-file-list') do
        expect(find('.id')).to have_text(batch_file.id)
      end
    end

    it 'displays path' do
      within('.batch-file-list') do
        expect(find('.path')).to have_text(batch_file.path)
      end
    end

    it 'displays status' do
      within('.batch-file-list') do
        expect(find('.status')).to have_text(batch_file.status.capitalize)
      end
    end

    context 'with additional information' do
      let(:additional_values) do
        {
          error_messages: ['example error'],
          started_at: 1.hour.ago,
          completed_at: Time.current
        }
      end

      it 'displays errors' do
        within('.batch-file-list') do
          expect(first('.error-message')).to have_text(batch_file.error_messages.first)
        end
      end

      it 'displays started_at' do
        within('.batch-file-list') do
          expect(find('.started-at')).to have_text(batch_file.started_at)
        end
      end

      it 'displays completed_at' do
        within('.batch-file-list') do
          expect(find('.completed-at')).to have_text(batch_file.completed_at)
        end
      end
    end

    it 'displays "None" when there are no errors' do
      within('.batch-file-list') do
        expect(find('.errors')).to have_text('None')
      end
    end

    it 'displays "Not Started" when batch file started-at is nil' do
      within('.batch-file-list') do
        expect(find('.started-at')).to have_text('Not Started')
      end
    end

    it 'displays "Not Completed" when batch file started-at is nil' do
      within('.batch-file-list') do
        expect(find('.completed-at')).to have_text('Not Completed')
      end
    end

    it 'displays created_at' do
      within('.batch-file-list') do
        expect(find('.created-at')).to have_text(batch_file.created_at)
      end
    end

    it 'displays updated_at' do
      within('.batch-file-list') do
        expect(find('.updated-at')).to have_text(batch_file.updated_at)
      end
    end
  end
end
