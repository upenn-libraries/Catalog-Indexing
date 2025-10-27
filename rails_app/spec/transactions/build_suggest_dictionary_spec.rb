# frozen_string_literal: true

describe BuildSuggestDictionary do
  include SolrHelpers

  let(:outcome) do
    described_class.new.call(collections: collections,
                             suggester: suggester,
                             dictionary: dictionary)
  end

  describe '#call' do
    context 'with a non-existent collection name' do
      let(:collections) { ['nope'] }
      let(:suggester) { 'whatever' }
      let(:dictionary) { 'whatever' }

      it 'returns a failure' do
        expect(outcome).to be_failure
        expect(outcome.failure[:message]).to eq "Collection 'nope' does not exist."
      end
    end

    context 'with multiple collection names' do
      let(:collections) { SolrTools.collections } # TODO: CI won't have two collections...
      let(:suggester) { 'whatever' }
      let(:dictionary) { 'whatever' }

      it 'returns a failure' do
        expect(outcome).to be_failure
        expect(outcome.failure[:message]).to be eq 'This transaction supports only a single collection name'
      end
    end

    context 'with missing suggester param' do
      let(:collections) { [test_collection] }
      let(:suggester) { nil }
      let(:dictionary) { 'whatever' }

      it 'returns a failure' do
        expect(outcome).to be_failure
        expect(outcome.failure[:message]).to be eq 'Collection, Suggester and Dictionary names must be provided'
      end
    end

    # context 'with Solr having an issue'
    # context 'with correct configuration' do
    #   it 'returns suggestions' do
    #     expect(solr.suggestions(collection:, suggester:, q:).count).to eq 1
    #   end
    # end
  end
end
