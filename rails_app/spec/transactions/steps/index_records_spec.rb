# frozen_string_literal: true

describe Steps::IndexRecords do
  include FixtureHelpers
  include SolrHelpers

  let(:outcome) { described_class.new.call(io: io, **additional_params) }
  let(:additional_params) do
    { writer: MultiCollectionWriter.new(collections: test_collection, commit_on_close: true) }
  end

  before { clear_collections }
  after { clear_collections }

  context 'with invalid IO' do
    let(:io) { [666] }

    it 'returns failure monad' do
      expect(outcome).to be_failure
      expect(outcome.failure).to include 'must pass in path or File'
    end
  end

  context 'with a good IO' do
    let(:sample_mmsid) { '9979201969103681' }
    let(:io) { StringIO.new(marc_fixture(sample_mmsid)) }
    let(:solr) { Solr::QueryClient.new(collection: test_collection) }
    let(:additional_params) do
      { writer: MultiCollectionWriter.new(collections: solr.collection, commit_on_close: true) }
    end

    it 'returns success monad and writes a record to Solr' do
      expect(outcome).to be_success
      solr_response = solr.get_by_id(sample_mmsid)
      expect(solr_response['response']['numFound']).to eq 1
    end
  end

  context 'with a skipped record' do
    let(:sample_mmsid) { '9979201969103681' }
    let(:indexer) { PennMarcIndexer.new({ 'skipped_record_limit' => 2 }) }
    let(:additional_params) { { indexer: indexer, writer: MultiCollectionWriter.new(collections: test_collection) } }
    let(:io) { StringIO.new(marc_fixture(sample_mmsid)) }

    before do
      allow_any_instance_of(Traject::Indexer::Context).to receive(:skip?).and_return(true)
      allow(Rails.logger).to receive(:info).at_least(:once)
    end

    it 'logs an error message' do
      expect(outcome).to be_success
      expect(Rails.logger).to have_received(:info).with(/Record skipped/)
    end

    context 'when exceeding the configured skip limit' do
      let(:indexer) { PennMarcIndexer.new({ 'skipped_record_limit' => 0, 'failed_record_limit' => 2 }) }

      it 'writes error messages and returns success' do
        expect(outcome).to be_success
        expect(outcome.success[:errors].first).to include 'Skipped record count exceeds limit'
      end
    end

    context 'when not exceeding the configured skip limit' do
      let(:indexer) { PennMarcIndexer.new({ 'skipped_record_limit' => 2, 'failed_record_limit' => 2 }) }

      it 'returns success and does not log an error message for the skipped record' do
        expect(outcome).to be_success
        expect(outcome.success[:errors].length).to eq 0
      end
    end
  end

  context 'with a record that raises an exception' do
    let(:io) { StringIO.new(marc_fixture('9979201969103681')) }
    let(:additional_params) { { indexer: indexer, writer: MultiCollectionWriter.new(collections: test_collection) } }

    before do
      allow(indexer).to receive(:map_to_context!).and_raise(StandardError)
    end

    context 'when not exceeding the configured error limit' do
      let(:indexer) { PennMarcIndexer.new({ 'failed_record_limit' => 2, 'skipped_record_limit' => 1 }) }

      it 'writes a single error message but returns success' do
        expect(outcome).to be_success
        expect(outcome.success[:errors].length).to eq 1
      end
    end

    context 'when exceeding the configured error limit' do
      let(:indexer) { PennMarcIndexer.new({ 'failed_record_limit' => 0, 'skipped_record_limit' => 1 }) }

      it 'writes error messages and returns success' do
        expect(outcome).to be_success
        expect(outcome.success[:errors].first).to include 'Failed record count exceeds limit'
      end
    end
  end

  context 'with multiple target_collections' do
    let(:additional_params) do
      { writer: MultiCollectionWriter.new(collections: collection_names, commit_on_close: true) }
    end
    let(:collection_names) { %w[tc-1 tc-2] }
    let(:sample_mmsid) { '9979201969103681' }
    let(:io) { StringIO.new(marc_fixture(sample_mmsid)) }

    before do
      create_collections collection_names
      outcome
    end

    after { remove_collections collection_names }

    it 'writes a record to tc-1' do
      query_client = Solr::QueryClient.new collection: 'tc-1'
      solr_response = query_client.get_by_id(sample_mmsid)
      expect(solr_response['response']['numFound']).to eq 1
    end

    it 'writes a record to tc-2' do
      query_client = Solr::QueryClient.new collection: 'tc-2'
      solr_response = query_client.get_by_id(sample_mmsid)
      expect(solr_response['response']['numFound']).to eq 1
    end
  end
end
