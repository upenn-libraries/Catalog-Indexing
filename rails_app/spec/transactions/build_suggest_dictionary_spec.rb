# frozen_string_literal: true

describe BuildSuggestDictionary do
  include SolrHelpers

  let(:outcome) do
    described_class.new.call(collections: collections, suggester: suggester, dictionary: dictionary)
  end

  before do
    allow(ConfigItem).to receive(:value_for).with(:incremental_target_collections).and_return(collections)
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

    context 'with missing suggester param' do
      let(:collections) { [test_collection] }
      let(:suggester) { nil }
      let(:dictionary) { 'whatever' }

      it 'returns a failure' do
        expect(outcome).to be_failure
        expect(outcome.failure[:message]).to eq 'Collection, Suggester and Dictionary names must be provided'
      end
    end

    context 'with Solr having an issue due to a non-existent suggester configuration' do
      let(:collections) { [test_collection] }
      let(:suggester) { 'whatever' }
      let(:dictionary) { 'whatever' }

      it 'returns a failure with exception information' do
        expect(outcome).to be_failure
        expect(outcome.failure[:message]).to include 'Searching for Solr?'
      end
    end

    context 'with the Solr request resulting in an exception' do
      let(:collections) { [test_collection] }
      let(:suggester) { Settings.suggester.handlers.title }
      let(:dictionary) { Settings.suggester.dictionaries.title }

      before { allow(Faraday).to receive(:get).and_raise(StandardError.new('terrible')) }

      it 'returns a failure with exception information' do
        expect(outcome).to be_failure
        expect(outcome.failure[:message]).to include 'terrible'
      end
    end

    context 'with a valid suggester configuration' do
      let(:collections) { ['suggester-test-collection'] }
      let(:suggester) { Settings.suggester.handlers.title }
      let(:dictionary) { Settings.suggester.dictionaries.title }

      before do
        SolrTools.create_collection collections.first
        solr = Solr::QueryClient.new(collection: collections.first)
        solr.add(docs: { id: '123', main_title_title_suggest: 'Test' })
        solr.commit
      end

      after { SolrTools.delete_collection collections.first }

      it 'returns one suggestion based on the one indexed record' do
        expect(outcome).to be_success
        sug_url = SolrTools.suggester_query_url(
          collection: collections.first,
          suggester: Settings.suggester.handlers.title,
          dictionary: Settings.suggester.dictionaries.title,
          query: 'T'
        )
        suggestions_resp = SolrTools.connection(url: sug_url).get
        count = suggestions_resp.body['suggest']['title']['T']['numFound']
        expect(count).to eq 1
      end
    end
  end
end
