# frozen_string_literal: true

describe IndexByIdentifiers do
  include AlmaApiMocks
  include FixtureHelpers
  include SolrHelpers

  let(:sample_mmsid) { '9979201969103681' }
  let(:marcxml) { marc_fixture sample_mmsid }
  let(:solr) { Solr::QueryClient.new(collection: test_collection) }
  let(:transaction) { described_class.new }
  let(:outcome) { transaction.call(identifiers: sample_mmsid) }

  before do
    solr.delete_all
    stub_bibs_request sample_mmsid, alma_sample_json_response(marcxml)
  end

  after { solr.delete_all }

  describe '#call' do
    context 'with a successful add' do
      before do
        allow(ConfigItem).to receive(:value_for).with(:adhoc_target_collections).and_return(test_collection)
      end

      it 'adds the record to the specified collections' do
        expect(outcome).to be_success
        expect(solr.get_by_id(sample_mmsid)['response']['numFound']).to eq 1
      end
    end

    context 'with a failed add' do
      it 'returns the failure message in some informative way' do
        expect(outcome).to be_failure
        expect(outcome.failure[:exception].message).to include 'Config Item is not initialized'
      end
    end
  end
end
