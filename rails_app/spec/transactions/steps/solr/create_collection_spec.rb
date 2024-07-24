# frozen_string_literal: true

describe Steps::Solr::CreateCollection do
  let(:result) { described_class.new.call(collection_name: collection_name) }
  let(:collection_name) { 'new-collection' }

  context 'when the collection does not exist' do
    before do
      allow(SolrTools).to receive(:collection_exists?).with(collection_name).and_return(false)
      allow(SolrTools).to receive(:create_collection).with(collection_name)
    end

    it 'returns a Success monad with collections array' do
      expect(result).to be_success
      expect(result.success[:collections]).to eq [collection_name]
    end
  end

  context 'when the collection already exists' do
    before do
      allow(SolrTools).to receive(:collection_exists?).with(collection_name).and_return(true)
    end

    it 'returns a Failure monad with message' do
      expect(result).to be_failure
      expect(result.failure).to include 'Solr collection new-collection already exists'
    end
  end
end
