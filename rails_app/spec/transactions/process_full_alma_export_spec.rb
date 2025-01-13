# frozen_string_literal: true

describe ProcessFullAlmaExport, stub_batches: true do
  include FixtureHelpers
  include SolrHelpers

  let(:transaction) { described_class.new }

  before { remove_collections(SolrTools.new_collection_name) }
  after { remove_collections(SolrTools.new_collection_name) }

  describe '#call' do
    let(:webhook) { Webhook::Job.new data: JSON.parse(json_fixture('job_end_success_full_publish', :webhooks)) }
    let(:alma_export) { create(:alma_export, :full, webhook_body: webhook.data, job_identifier: webhook.id ) }
    let(:outcome) { transaction.call(alma_export_id: alma_export.id) }

    context 'with valid webhook response body' do
      include_context 'with sftp files available'

      it 'is successful' do
        expect(outcome).to be_success
      end

      it 'enqueues the right number of ProcessBatchFileJobs' do
        expect { outcome }.to change { ProcessBatchFileJob.jobs.count }.by sftp_files.count
      end

      it 'creates BatchFiles' do
        alma_export = outcome.success[:alma_export]
        expect(alma_export.batch_files.count).to eq sftp_files.count
      end

      it 'set the right attributes on the AlmaExport' do
        alma_export = outcome.success[:alma_export]
        expect(alma_export.status).to eq Statuses::IN_PROGRESS
        expect(alma_export.started_at).to be_present
      end

      it 'creates a new collection in Solr and saves it on the AlmaExport' do
        alma_export = outcome.success[:alma_export]
        expect(alma_export.target_collections).to eq [SolrTools.new_collection_name]
        expect(SolrTools.collection_exists?(alma_export.target_collections.first)).to be true
      end
    end

    context 'with no sftp files available' do
      include_context 'with sftp files available'

      let(:sftp_files) { [] }

      it 'returns a failure monad and appropriate message' do
        expect(outcome).to be_failure
        expect(outcome.failure[:message]).to eq 'No SFTP files found!'
      end
    end
  end
end
