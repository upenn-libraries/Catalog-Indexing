# frozen_string_literal: true

describe DeleteByIdentifier do
  include FixtureHelpers
  include SolrHelpers

  let(:sample_mmsid) { '9979201969103681' }
  let(:solr) { Solr::QueryClient.new(collection: test_collection) }
  let(:transaction) { described_class.new }
  let(:outcome) { transaction.call(id: sample_mmsid, commit: true, collections: Array.wrap(solr.collection)) }

  before { solr.delete_all }
  after { solr.delete_all }

  describe '#call' do
    context 'with a successful delete' do
      before do
        solr.add(docs: { id: sample_mmsid })
        solr.commit
      end

      it 'removes the record from the specified collections' do
        expect(outcome).to be_success
        expect(solr.get_by_id(sample_mmsid)['response']['numFound']).to eq 0
      end

      it 'returns an appropriate message' do
        expect(outcome.success).to include sample_mmsid
      end
    end

    context 'with a failed delete' do
      before do
        allow(solr).to receive(:collection).and_return('bad-collection-name')
      end

      it 'returns the failure message in some informative way' do
        expect(outcome).to be_failure
        expect(outcome.failure[:exception].message).to include 'bad-collection-name'
      end
    end
  end
end
