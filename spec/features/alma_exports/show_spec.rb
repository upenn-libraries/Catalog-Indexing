# frozen_string_literal: true

describe 'Alma Export Show Page' do
  let(:user) { create(:user) }

  before { sign_in user }

  context 'when viewing batch files' do
    let(:alma_export) { create(:alma_export_with_files, **additional_values) }
    let(:additional_values) { {} }

    before { visit alma_export_path(alma_export) }

    it 'displays ID' do
      within('.alma-export-list') do
        expect(find('.id')).to have_text(alma_export.id)
      end
    end

    it 'displays status' do
      within('.alma-export-list') do
        expect(find('.status')).to have_text(alma_export.status.capitalize)
      end
    end

    it 'displays source' do
      within('.alma-export-list') do
        expect(find('.source')).to have_text(alma_export.alma_source)
      end
    end

    it 'displays full' do
      within('.alma-export-list') do
        expect(find('.full')).to have_text(alma_export.full.to_s.capitalize)
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
        within('.alma-export-list') do
          expect(find('.started-at')).to have_text(alma_export.started_at&.to_fs(:display))
        end
      end

      it 'displays completed_at' do
        within('.alma-export-list') do
          expect(find('.completed-at')).to have_text(alma_export.completed_at&.to_fs(:display))
        end
      end
    end

    it 'displays Not Started when started_at is nil' do
      within('.alma-export-list') do
        expect(find('.started-at')).to have_text('Not Started')
      end
    end

    it 'displays Not Completed when completed_at is nil' do
      within('.alma-export-list') do
        expect(find('.completed-at')).to have_text('Not Completed')
      end
    end

    it 'displays created_at' do
      within('.alma-export-list') do
        expect(find('.created-at')).to have_text(alma_export.created_at.to_fs(:display))
      end
    end

    it 'displays updated_at' do
      within('.alma-export-list') do
        expect(find('.updated-at')).to have_text(alma_export.updated_at.to_fs(:display))
      end
    end

    it 'displays webhook_body' do
      within('.alma-export-list') do
        expect(find('pre')).to have_text(JSON.pretty_generate(alma_export.webhook_body).squish)
      end
    end

    it 'displays button to batch files' do
      expect(page).to have_link('Show Batch Files')
    end
  end
end
