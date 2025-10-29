# frozen_string_literal: true

describe BuildSuggestDictionary do
  include SolrHelpers

  let(:outcome) do
    described_class.new.call(collections: collections, suggester: suggester, dictionary: dictionary)
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
      let(:collections) { SolrTools.collections }
      let(:suggester) { 'whatever' }
      let(:dictionary) { 'whatever' }

      it 'returns a failure' do
        expect(outcome).to be_failure
        expect(outcome.failure[:message]).to eq 'This transaction supports only a single collection name'
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
        expect(outcome.failure[:message]).to include '404'
      end
    end

    context 'with the Solr request resulting in an exception' do
      let(:collections) { [test_collection] }
      let(:suggester) { Settings.suggester.handlers.title }
      let(:dictionary) { Settings.suggester.dictionaries.title }

      before do
        mock_connection = instance_double(Faraday::Connection)
        allow(mock_connection).to receive(:get).and_raise(StandardError.new('terrible'))
        allow(SolrTools).to receive(:connection).and_call_original
        allow(SolrTools).to receive(:connection).with(hash_including(url: /title/)).and_return(mock_connection)
      end

      it 'returns a failure with exception information' do
        expect(outcome).to be_failure
        expect(outcome.failure[:message]).to include 'terrible'
      end
    end

    context 'with a valid suggester configuration' do
      let(:collections) { [test_collection] }
      let(:suggester) { Settings.suggester.handlers.title }
      let(:dictionary) { Settings.suggester.dictionaries.title }

      before do
        solr = Solr::QueryClient.new(collection: test_collection)
        solr.delete_all
        solr.commit
        solr.add(docs: { id: '123', main_title_title_suggest: 'Test' })
        solr.commit
      end

      it 'returns one suggestion based on the one indexed record' do
        expect(outcome).to be_success
        suggestions_resp = SolrTools.connection(
          url: SolrTools.suggester_uri(
            collection: collections.first,
            suggester: Settings.suggester.handlers.title,
            dictionary: Settings.suggester.dictionaries.title,
            build: true, query: 'T'
          )
        ).get
        count = suggestions_resp.body['suggest']['title']['T']['numFound']
        expect(count).to eq 1
      end
    end
  end
end
