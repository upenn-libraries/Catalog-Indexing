# frozen_string_literal: true

describe 'Batch Files Show Page' do
  let(:user) { create(:user) }

  before { sign_in user }

  context 'when viewing batch files' do
    let(:alma_export) { create(:alma_export_with_files) }
    let(:batch_file) { alma_export.batch_files.first }

    before { visit alma_export_batch_file_path(alma_export, batch_file) }

    it 'shows parent alma export' do
      expect(page).to have_text("Belongs to Alma Export: #{alma_export.id}")
    end

    it 'displays ID' do
      within('tr.id') do
        expect(page).to have_text(batch_file.id)
      end
    end

    it 'displays path' do
      within('tr.path') do
        expect(page).to have_text(batch_file.path)
      end
    end

    it 'displays status' do
      within('tr.status') do
        expect(page).to have_text(batch_file.status)
      end
    end

    it 'displays "None" when there are no errors' do
      within(first('tr.errors')) { expect(page).to have_text('None') }
    end

    # Todo Implement spec for displaying batch file with errors
    # it 'displays errors' do
    #   within('tr.errors') do
    #     expect(page).to have_text(batch_file.error_messages.first)
    #   end
    # end

    it 'displays "Not Started" when batch file started-at is nil' do
      within(first('tr.started-at')) { expect(page).to have_text('Not Started') }
    end

    # Todo Implement spec for displaying batch file started-at when it's not nil
    # it 'displays started_at' do
    #   within('tr.started-at') do
    #     expect(page).to have_text(batch_file.started_at)
    #   end
    # end

    it 'displays "Not Completed" when batch file started-at is nil' do
      within(first('tr.completed-at')) { expect(page).to have_text('Not Completed') }
    end

    # Todo Implement spec for displaying batch file completed-at when it's not nil
    # it 'displays completed_at' do
    #   within('tr.completed-at') do
    #     expect(page).to have_text(batch_file.completed_at)
    #   end
    # end

    it 'displays created_at' do
      within('tr.created-at') do
        expect(page).to have_text(batch_file.created_at)
      end
    end

    it 'displays updated_at' do
      within('tr.updated-at') do
        expect(page).to have_text(batch_file.updated_at)
      end
    end
  end
end
