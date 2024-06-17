# frozen_string_literal: true

describe DeleteByIdentifier do
  include FixtureHelpers
  include SolrHelpers

  let(:sample_mmsid) { '9979201969103681' }
  let(:solr) { Solr::QueryClient.new(collection: test_collection) }
  let(:transaction) { described_class.new }
  let(:outcome) { transaction.call(id: sample_mmsid) }

  before do
    allow(ConfigItem).to receive(:value_for).with(:webhook_target_collections)
                                            .and_return(Array.wrap(solr.collection))
    solr.delete_all
  end

  after { solr.delete_all }

  describe '#call' do
    context 'with a successful delete' do
      before do
        # index a record
        # commit
      end

      xit 'removes the record from Solr'
    end

    context 'with a failed delete' do
      before do
        # stub solr error/exception
      end

      xit 'returns the failure message in some informative way'
    end
  end
end
