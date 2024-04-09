# frozen_string_literal: true

describe IndexByBibEvent do
  include FixtureHelpers

  let(:sample_mmsid) { '9979201969103681' }
  let(:marcxml) { marc_fixture sample_mmsid }
  let(:solr) { Solr::QueryClient.new }
  let(:transaction) { described_class.new }
  let(:outcome) { transaction.call(docs: marcxml) }

  before do
    allow(ConfigItem).to receive(:value_for).with(:webhook_target_collections)
                                            .and_return(Solr::Config.new.collection_name)
    solr.delete_all
  end

  after { solr.delete_all }

  describe '#call' do
    context 'with valid marcxml record' do
      it 'returns a success monad' do
        expect(outcome).to be_success
      end

      it 'indexes record to solr' do
        outcome
        solr.commit
        solr_response = solr.get_by_id(sample_mmsid)
        expect(solr_response['response']['numFound']).to eq 1
      end
    end

    context 'with invalid marcxml record' do
      let(:marcxml) { '<' }

      it 'returns a failure monad' do
        expect(outcome).to be_failure
      end
    end
  end
end
