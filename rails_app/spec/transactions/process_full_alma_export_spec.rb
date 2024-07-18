# frozen_string_literal: true

describe ProcessFullAlmaExport do
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
      after { SolrTools.delete_collection(SolrTools.new_collection_name) }

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

      it 'returns appropriate failure and saves the error message' do
        expect(outcome.failure).to include 'already exists'
        expect(alma_export.reload.error_messages).to include outcome.failure
      end
    end

    context 'with a bad AlmaExport identifier' do
      before do
        allow(AlmaExport).to receive(:find).and_raise ActiveRecord::RecordNotFound
      end

      it 'returns a failure monad with appropriate message' do
        expect(outcome).to be_failure
        expect(outcome.failure).to include('does not exist')
      end
    end

    context 'with an AlmaExport not in PENDING status' do
      let(:alma_export) do
        create(:alma_export, status: Statuses::IN_PROGRESS,
                             webhook_body: JSON.parse(json_fixture('job_end_success_full_publish', :webhooks)))
      end

      it 'returns a failure monad with appropriate message' do
        expect(outcome.failure).to include 'must be in \'pending\' state'
        expect(alma_export.reload.error_messages).to include outcome.failure
      end
    end

    context 'with no files matching on SFTP server' do
      let(:sftp_files) { [] }

      it 'returns a failure monad with appropriate message' do
        expect(outcome.failure).to include('No files downloaded')
        expect(alma_export.reload.error_messages).to include outcome.failure
      end
    end

    context 'with an unexpected SFTP error' do
      let(:sftp_files) { ['dummy_file'] }

      before do
        allow(sftp_client).to receive(:download).and_raise Sftp::Client::Error
      end

      it 'returns a failure monad with appropriate message' do
        expect(outcome.failure).to include('processing SFTP file')
        expect(alma_export.reload.error_messages).to include outcome.failure
      end
    end
  end

  describe '#files_matching_regex' do
    let(:files) do
      [
        '.', '..', # returned by dir.entries command, ignore
        'prefix_123456789_2023010100_new_1.tar.gz',
        'prefix_123456789_2023010100_new_23.tar.gz',
        'prefix_123456789_2023010100_new_900.tar.gz',
        'prefix_123456789_2023010100_new_1.zip', # wrong extension
        'prefix_555555555_2023010100_new_1.xml.tar.gz' # wrong job id
      ]
    end

    it 'can be used to select only the desired files' do
      regex = transaction.files_matching_regex('123456789')
      expect(files.grep(regex)).to eq %w[prefix_123456789_2023010100_new_1.tar.gz
                                         prefix_123456789_2023010100_new_23.tar.gz
                                         prefix_123456789_2023010100_new_900.tar.gz]
    end

    it 'returns no files if a blank parameter is provided' do
      regex = transaction.files_matching_regex(nil)
      expect(files.grep(regex)).to be_empty
    end
  end
end
