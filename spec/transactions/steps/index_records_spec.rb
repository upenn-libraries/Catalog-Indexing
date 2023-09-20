# frozen_string_literal: true

describe Steps::IndexRecords do
  include FixtureHelpers

  let(:sample_mmsid) { '9979201969103681' }
  let(:marcxml) { marc_fixture sample_mmsid }
  let(:io) { StringIO.new(marcxml) }
  let(:solr_query_client) { Solr::QueryClient.new }

  before do
    solr_query_client.delete_all
    solr_query_client.commit
  end

  after do
    solr_query_client.delete_all
    solr_query_client.commit
  end

  describe '#call' do
    let(:step) { described_class.new }

    context 'with invalid IO' do
      it 'returns failure monad' do
        expect(step.call(io: [666])).to be_failure
      end
    end

    context 'with a good IO' do
      it 'returns success monad and writes a record to Solr' do
        expect(step.call(io: io, commit: true)).to be_success
        solr_response = solr_query_client.get_by_id(sample_mmsid)
        expect(solr_response['response']['numFound']).to eq 1
      end
    end

    context 'with a skipped record' do
      let(:outcome) { step.call(io: io) }

      before do
        allow_any_instance_of(Traject::Indexer::Context).to receive(:skip?).and_return(true)
      end

      it 'writes an error message' do
        expect(outcome).to be_success
        expect(outcome.success[:errors].first).to include 'Record skipped'
      end
    end

    context 'with an exception raised in the indexer' do
      let(:indexer) { PennMarcIndexer.new }
      let(:outcome) { step.call(io: io, indexer: indexer) }

      before do
        allow(indexer).to receive(:map_to_context!).and_raise(StandardError)
      end

      it 'writes an error message' do
        expect(outcome).to be_success
        expect(outcome.success[:errors].first).to include 'Error during record processing'
      end
    end

    context 'with multiple target_collections' do
      before do
        solr_config = Solr::Admin.new
        solr_config.delete_collection 'test-collection-1' if solr_config.collection_exists? name: 'test-collection-1'
        solr_config.delete_collection 'test-collection-2' if solr_config.collection_exists? name: 'test-collection-2'
        solr_config.create_collection name: 'test-collection-1'
        solr_config.create_collection name: 'test-collection-2'
      end

      after do
        solr_config = Solr::Admin.new
        solr_config.delete_collection 'test-collection-1'
        solr_config.delete_collection 'test-collection-2'
      end

      it 'writes a record to both collections' do
        indexer = PennMarcIndexer.new({ 'solr_writer.target_collections' => %w[test-collection-1 test-collection-2] })
        step.call(io: io, indexer: indexer, commit: true)
        tc_1_query_client = Solr::QueryClient.new collection: 'test-collection-1'
        tc_2_query_client = Solr::QueryClient.new collection: 'test-collection-2'
        tc_1_solr_response = tc_1_query_client.get_by_id(sample_mmsid)
        tc_2_solr_response = tc_2_query_client.get_by_id(sample_mmsid)
        expect(tc_1_solr_response['response']['numFound']).to eq 1
        expect(tc_2_solr_response['response']['numFound']).to eq 1
      end
    end
  end
end
