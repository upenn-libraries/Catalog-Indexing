# frozen_string_literal: true

describe DeleteByIdentifier do
  include FixtureHelpers
  include SolrHelpers

  let(:sample_mmsid) { '9979201969103681' }
  let(:solr) { Solr::QueryClient.new(collection: test_collection) }
  let(:transaction) { described_class.new }
  let(:outcome) { transaction.call(id: sample_mmsid, commit_within: 1, collections: Array.wrap(solr.collection)) }

  before { solr.delete_all }
  after { solr.delete_all }

  describe '#call' do
    context 'with a successful delete' do
      before do
        solr.add(docs: { id: sample_mmsid })
        solr.commit
      end

      it 'removes the record from Solr' do
        expect(outcome).to be_success
        expect(solr.get_by_id(sample_mmsid)['response']['numFound']).to eq 0
      end
    end

    context 'with a failed delete' do
      # before do
      #   # TODO: how to simulate an error?
      # end

      xit 'returns the failure message in some informative way'
    end
  end
end
