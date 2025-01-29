# frozen_string_literal: true

describe 'Alma Export Show Page' do
  include FixtureHelpers

  let(:user) { create(:user) }

  before { sign_in user }

  context 'when viewing an alma export' do
    let(:alma_export) { create(:alma_export_with_files, **additional_values) }
    let(:additional_values) { {} }

    before { visit alma_export_path(alma_export) }

    describe 'export details' do
      it 'displays id' do
        within('.export-info') do
          expect(page).to have_content(alma_export.id)
        end
      end

      it 'displays alma source' do
        within('.export-info') do
          expect(page).to have_content(alma_export.alma_source)
        end
      end

      it 'displays status' do
        within('.export-info') do
          expect(page).to have_content(alma_export.status.titleize)
        end
      end

      it 'displays full' do
        within('.export-info') do
          expect(page).to have_content(alma_export.full.to_s.titleize)
        end
      end

      it 'displays target collections when present' do
        within('.export-info') do
          alma_export.target_collections.each do |collection|
            expect(page).to have_content(collection)
          end
        end
      end
    end

    describe 'indexing details with additional values' do
      let(:additional_values) do
        {
          started_at: 1.hour.ago,
          completed_at: Time.current
        }
      end

      it 'displays started_at' do
        within('.indexing-info') do
          expect(page).to have_content(alma_export.started_at.to_fs(:display))
        end
      end

      it 'displays completed_at' do
        within('.indexing-info') do
          expect(page).to have_content(alma_export.completed_at.to_fs(:display))
        end
      end

      it 'displays created_at' do
        within('.indexing-info') do
          expect(page).to have_content(alma_export.created_at.to_fs(:display))
        end
      end

      it 'displays updated_at' do
        within('.indexing-info') do
          expect(page).to have_content(alma_export.updated_at.to_fs(:display))
        end
      end
    end

    describe 'indexing details without start/completion times' do
      it 'does not display started_at' do
        within('.indexing-info') do
          expect(page).to have_content('Not Started')
        end
      end

      it 'does not display completed_at' do
        within('.indexing-info') do
          expect(page).to have_content('Not Completed')
        end
      end

      it 'displays created_at' do
        within('.indexing-info') do
          expect(page).to have_content(alma_export.created_at.to_fs(:display))
        end
      end

      it 'displays updated_at' do
        within('.indexing-info') do
          expect(page).to have_content(alma_export.updated_at.to_fs(:display))
        end
      end

      it 'displays batch files button when files exist' do
        within('.indexing-info') do
          expect(page).to have_link('Show Batch Files')
        end
      end
    end

    describe 'job details' do
      let(:additional_values) do
        { webhook_body: JSON.parse(json_fixture('job_end_success_full_publish', :webhooks)) }
      end

      it 'displays job identifier' do
        within('.job-info') do
          expect(page).to have_content(alma_export.job_identifier)
        end
      end

      it 'displays job started at' do
        within('.job-info') do
          expect(page).to have_content(alma_export.job_started_at.to_fs(:display))
        end
      end

      it 'displays job ended at' do
        within('.job-info') do
          expect(page).to have_content(alma_export.job_ended_at.to_fs(:display))
        end
      end

      it 'displays job duration' do
        within('.job-info') do
          expect(page).to have_content(alma_export.job_duration)
        end
      end

      it 'displays webhook body' do
        within('.job-info') do
          expect(page).to have_selector('pre')
        end
      end
    end
  end
end
