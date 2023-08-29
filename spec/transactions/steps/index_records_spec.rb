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
  end
end
