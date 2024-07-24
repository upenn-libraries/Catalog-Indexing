# frozen_string_literal: true

describe Steps::Solr::ValidateCollections do
  let(:result) { described_class.new.call(collections: collections) }

  context 'with one existing nd not existing collection' do
    let(:collections) { %w[gone-collection collection] }

    before do
      allow(SolrTools).to receive(:collection_exists?).with(collections.first).and_return(false)
    end

    it 'returns a Failure monad with expected message' do
      expect(result).to be_failure
      expect(result.failure).to eq "Collection 'gone-collection' does not exist."
    end
  end

  context 'with only existing collections' do
    let(:collections) { %w[collection other_collection] }

    before do
      collections.each do |collection_name|
        allow(SolrTools).to receive(:collection_exists?).with(collection_name).and_return(true)
      end
    end

    it 'returns a Success monad with collections array' do
      expect(result).to be_success
      expect(result.success[:collections]).to eq collections
    end
  end

  context 'with no collections' do
    let(:collections) { [] }

    it 'returns Failure monad with expected message' do
      expect(result).to be_failure
      expect(result.failure).to eq 'No target collections configured!'
    end
  end
end
