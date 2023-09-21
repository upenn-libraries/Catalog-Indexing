# frozen_string_literal: true

describe Steps::IndexRecords do
  include FixtureHelpers

  let(:solr_query_client) { Solr::QueryClient.new }
  let(:outcome) { described_class.new.call(io: io, **additional_params) }
  let(:additional_params) { {} }

  before do
    solr_query_client.delete_all
    solr_query_client.commit
  end

  after do
    solr_query_client.delete_all
    solr_query_client.commit
  end

  describe '#call' do
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
      let(:additional_params) { { commit: true } }

      it 'returns success monad and writes a record to Solr' do
        expect(outcome).to be_success
        solr_response = solr_query_client.get_by_id(sample_mmsid)
        expect(solr_response['response']['numFound']).to eq 1
      end
    end

    context 'with a skipped record' do
      let(:sample_mmsid) { '9979201969103681' }
      let(:io) { StringIO.new(marc_fixture(sample_mmsid)) }

      before do
        allow_any_instance_of(Traject::Indexer::Context).to receive(:skip?).and_return(true)
      end

      it 'writes an error message' do
        expect(outcome).to be_success
        expect(outcome.success[:errors].first).to include 'Record skipped'
      end
    end

    context 'with a record that raises an exception' do
      let(:indexer) { PennMarcIndexer.new }
      let(:io) { StringIO.new(marc_fixture('9979201969103681')) }
      let(:additional_params) { { indexer: indexer } }

      before do
        allow(indexer).to receive(:map_to_context!).and_raise(StandardError)
      end

      it 'writes an error message' do
        expect(outcome).to be_success
        expect(outcome.success[:errors].first).to include 'Error during record processing'
      end
    end
  end

  context 'with multiple target_collections' do
    let(:additional_params) do
      { indexer: PennMarcIndexer.new({ 'solr_writer.target_collections' => %w[tc-1 tc-2] }), commit: true }
    end
    let(:sample_mmsid) { '9979201969103681' }
    let(:io) { StringIO.new(marc_fixture(sample_mmsid)) }

    before do
      solr_config = Solr::Admin.new
      solr_config.delete_collection 'tc-1' if solr_config.collection_exists? name: 'tc-1'
      solr_config.delete_collection 'tc-2' if solr_config.collection_exists? name: 'tc-2'
      solr_config.create_collection name: 'tc-1'
      solr_config.create_collection name: 'tc-2'
    end

    after do
      solr_config = Solr::Admin.new
      solr_config.delete_collection 'tc-1'
      solr_config.delete_collection 'tc-2'
    end

    it 'writes a record to both collections' do
      outcome
      tc_1_query_client = Solr::QueryClient.new collection: 'tc-1'
      tc_2_query_client = Solr::QueryClient.new collection: 'tc-2'
      tc_1_solr_response = tc_1_query_client.get_by_id(sample_mmsid)
      tc_2_solr_response = tc_2_query_client.get_by_id(sample_mmsid)
      expect(tc_1_solr_response['response']['numFound']).to eq 1
      expect(tc_2_solr_response['response']['numFound']).to eq 1
    end
  end
end
