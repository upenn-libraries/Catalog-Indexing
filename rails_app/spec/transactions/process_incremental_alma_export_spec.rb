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
    let(:webhook) { Webhook::Job.new data: JSON.parse(json_fixture('job_end_success_incremental', :webhooks)) }
    let(:alma_export) { create(:alma_export, :incremental, webhook_body: webhook.data, job_identifier: webhook.id) }
    let(:collections) { ['existing-collection'] }
    let(:outcome) { transaction.call(alma_export_id: alma_export.id) }

    include_context 'with incremental sftp files available'
    include_context 'with solr collections supporting deletes'

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

      # `satisfy` matcher used when checking that the expected IDs are deleted when using the delete file fixture
      # @see https://rspec.info/features/3-12/rspec-mocks/setting-constraints/matching-arguments/
      it 'sends DELETE to Solr with a hash containing an array of IDs' do
        outcome
        expect(mock_client).to have_received(:delete).with(
          satisfy { |data| data[:ids].length == 741 }
        )
      end

      it 'sets the right attributes on the AlmaExport' do
        alma_export = outcome.success[:alma_export]
        expect(alma_export.target_collections).to eq collections
        expect(alma_export.started_at).to be_present
      end
    end
  end
end
