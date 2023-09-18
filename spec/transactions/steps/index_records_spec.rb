# frozen_string_literal: true

describe Steps::IndexRecords do
  include FixtureHelpers

  let(:sample_mmsid) { '9979201969103681' }
  let(:marcxml) { marc_fixture sample_mmsid }
  let(:io) { StringIO.new(marcxml) }
  let(:solr) { Solr::QueryClient.new }

  before { solr.delete_all }
  after { solr.delete_all }

  describe '#call' do
    let(:step) { described_class.new }

    context 'with invalid IO' do
      it 'returns failure monad' do
        expect(step.call(io: [666])).to be_failure
      end
    end

    context 'with a good IO' do
      it 'returns success monad and writes a record to Solr' do
        expect(step.call(io: io)).to be_success
        solr_response = solr.get_by_id(sample_mmsid)
        expect(solr_response['response']['numFound']).to eq 1
      end
    end

    context 'with multiple target_collections' do
      before do
        solr_config = Solr::Admin.new
        solr_config.create_collection name: 'test-collection-1'
        solr_config.create_collection name: 'test-collection-2'
      end

      after do
        solr_config = Solr::Admin.new
        solr_config.delete_collection 'test-collection-1'
        solr_config.delete_collection 'test-collection-2'
      end

      it 'writes a record to both collections' do
        indexer = Traject::Indexer.new({ 'solr_writer.target_collections' => %w[test-collection-1 test-collection-2] })
        step.call(io: io, indexer: indexer)
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
