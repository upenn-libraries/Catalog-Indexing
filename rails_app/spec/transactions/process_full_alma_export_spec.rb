# frozen_string_literal: true

describe ProcessFullAlmaExport, stub_batches: true do
  include FixtureHelpers
  include SolrHelpers

  let(:transaction) { described_class.new }

  before { remove_collections(SolrTools.new_collection_name) }
  after { remove_collections(SolrTools.new_collection_name) }

  describe '#call' do
    let(:alma_export) do
      create(:alma_export, :full, webhook_body: JSON.parse(json_fixture('job_end_success_full_publish', :webhooks)))
    end
    let(:outcome) { transaction.call(alma_export_id: alma_export.id) }

    include_context 'with sftp files available'

    context 'with valid webhook response body' do
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

    context 'with an existing collection matching the new collection name' do
      before do
        allow(SolrTools).to receive(:collection_exists?).with(SolrTools.new_collection_name).and_return true
      end

      # Unstub above - this allows the spec-wide after hook to run without exception
      after { RSpec::Mocks.space.proxy_for(SolrTools).reset }

      it 'returns appropriate failure message' do
        expect(outcome.failure).to include 'already exists'
      end
    end
  end
end
