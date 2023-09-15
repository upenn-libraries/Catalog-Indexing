# frozen_string_literal: true

describe 'Batch Files Index Page' do
  let(:user) { create(:user) }

  before { sign_in user }

  context 'when viewing batch files' do
    let(:alma_export) { create(:alma_export_with_files) }
    let(:batch_file) { alma_export.batch_files.first }

    before { visit alma_export_batch_files_path(alma_export) }

    it 'displays ID of alma export' do
      expect(page).to have_text("Batch Files for Alma Export: #{alma_export.id}")
    end

    it 'lists all batch files' do
      expect(page).to have_css('tr.batch-file', count: alma_export.batch_files.count)
    end

    it 'displays IDs' do
      within(first('th.id')) { expect(page).to have_link(batch_file.id.to_s) }
    end

    it 'displays path' do
      within(first('td.path')) { expect(page).to have_text(batch_file.path) }
    end

    it 'displays status' do
      within(first('td.status')) { expect(page).to have_text(batch_file.status.capitalize) }
    end

    it 'displays "None" when there are no errors' do
      within(first('td.errors')) { expect(page).to have_text('None') }
    end

    # Todo Implement spec for displaying batch file with errors
    # it 'displays errors' do
    #   within('td.errors') do
    #     expect(page).to have_text(batch_file.errors)
    #   end
    # end

    it 'displays "Not Started" when batch file started-at is nil' do
      within(first('td.started-at')) { expect(page).to have_text('Not Started') }
    end

    # Todo Implement spec for displaying batch file started-at when it's not nil
    # it 'displays started-at' do
    #   within('td.started-at') do
    #     expect(page).to have_text(batch_file.started_at)
    #   end
    # end

    it 'displays "Not Completed" when batch file started-at is nil' do
      within(first('td.completed-at')) { expect(page).to have_text('Not Completed') }
    end

    # Todo Implement spec for displaying batch file completed-at when it's not nil
    # it 'displays completed-at' do
    #   within('td.completed-at') do
    #     expect(page).to have_text(batch_file.completed-at)
    #   end
    # end

    it 'displays created-at' do
      within(first('td.created-at')) { expect(page).to have_text(batch_file.created_at) }
    end

    it 'displays updated-at' do
      within(first('td.updated-at')) { expect(page).to have_text(batch_file.updated_at) }
    end
  end
end
