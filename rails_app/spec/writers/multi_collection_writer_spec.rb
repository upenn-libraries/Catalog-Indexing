# frozen_string_literal: true

describe MultiCollectionWriter do
  let(:writer) { described_class.new(collections: ['c1'], **args) }

  describe '#settings' do
    context 'with commit_on_close set to true' do
      let(:args) { { commit_on_close: true } }

      it 'sets the proper setting values' do
        expect(writer.settings).to include('solr_writer.commit_on_close' => true)
        expect(writer.settings.keys).not_to include('solr_writer.commit_within')
      end
    end

    context 'with commit_within set' do
      let(:args) { { commit_within: '1' } }

      it 'sets the proper settings values' do
        expect(writer.settings['solr_writer.solr_update_args']).to include('commitWithin' => args[:commit_within])
        expect(writer.settings.keys).not_to include('solr_writer.commit_on_close')
      end
    end
  end
end
