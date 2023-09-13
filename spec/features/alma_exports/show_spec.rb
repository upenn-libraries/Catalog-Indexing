# frozen_string_literal: true

describe 'Alma Export Show Page' do
  let(:user) { create(:user) }

  before { sign_in user }

  context 'when viewing batch files' do
    let(:alma_export) { create(:alma_export_with_files) }

    before { visit alma_export_path(alma_export) }

    it 'displays ID' do
      within('tr.id') do
        expect(page).to have_text(alma_export.id)
      end
    end

    it 'displays status' do
      within('tr.status') do
        expect(page).to have_text(alma_export.status)
      end
    end

    it 'displays source' do
      within('tr.source') do
        expect(page).to have_text(alma_export.alma_source)
      end
    end

    it 'displays full' do
      within('tr.full') do
        expect(page).to have_text(alma_export.full)
      end
    end

    it 'displays webhook_body' do
      within('pre') do
        expect(page).to have_text('12345678')
      end
    end

    it 'displays started_at' do
      within('tr.started-at') do
        expect(page).to have_text(alma_export.started_at)
      end
    end

    it 'displays completed_at' do
      within('tr.completed-at') do
        expect(page).to have_text(alma_export.completed_at)
      end
    end

    it 'displays created_at' do
      within('tr.updated-at') do
        expect(page).to have_text(alma_export.created_at)
      end
    end

    it 'displays updated_at' do
      within('tr.updated-at') do
        expect(page).to have_text(alma_export.updated_at)
      end
    end

    it 'displays button to batch files' do
      expect(page).to have_link('Show Batch Files')
    end
  end
end
