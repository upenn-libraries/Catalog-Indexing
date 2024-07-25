# frozen_string_literal: true

describe ProcessIncrementalAlmaExport, stub_batches: true do
  include FixtureHelpers
  include SolrHelpers

  let(:transaction) { described_class.new }

  before do
    allow(ConfigItem).to receive(:value_for).with(:incremental_target_collections).and_return(collections)
    collections.each { |c| allow(SolrTools).to receive(:collection_exists?).with(c).and_return(true) }
  end

  describe '#call' do
    let(:alma_export) do
      create(:alma_export, :incremental,
             webhook_body: JSON.parse(json_fixture('job_end_success_incremental', :webhooks)))
    end
    let(:collections) { ['existing-collection'] }
    let(:outcome) { transaction.call(alma_export_id: alma_export.id) }

    include_context 'with incremental sftp files available'

    before do
      mock_client = instance_double Solr::QueryClient
      mock_response = instance_double RSolr::HashWithResponse
      allow(mock_response).to receive(:response).and_return({ status: 200 })
      allow(mock_client).to receive(:delete).and_return(mock_response)
      allow(Solr::QueryClient).to receive(:new).with(collection: collections.first).and_return(mock_client)
    end

    context 'with valid webhook response body' do
      it 'is successful' do
        expect(outcome).to be_success
      end

      it 'enqueues the right number of ProcessBatchFileJobs' do
        expect { outcome }.to change { ProcessBatchFileJob.jobs.count }.by 1
      end

      it 'creates BatchFiles' do
        alma_export = outcome.success[:alma_export]
        expect(alma_export.batch_files.count).to eq 1
      end

      it 'set the right attributes on the AlmaExport' do
        alma_export = outcome.success[:alma_export]
        expect(alma_export.target_collections).to eq collections
        expect(alma_export.started_at).to be_present
      end
    end
  end
end
