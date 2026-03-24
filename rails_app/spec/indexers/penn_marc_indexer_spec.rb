# frozen_string_literal: true

describe PennMarcIndexer do
  include PennMARC::Test::MarcHelpers

  let(:indexer) { described_class.new }
  let(:result) { indexer.map_record(record) }
  let(:record) { marc_record(fields: fields) }

  context 'with a record that should be skipped because it is a host record' do
    let(:fields) do
      [marc_control_field(tag: '001', value: '12345'),
       marc_field(tag: '245', subfields: { a: "#{PennMARC::Title::HOST_BIB_TITLE} for Blah" })]
    end

    it 'returns nil' do
      expect(result).to be_nil
    end
  end

  context 'with a typical record' do
    let(:fields) do
      [marc_control_field(tag: '001', value: '12345'),
       marc_field(tag: '245', subfields: { a: 'Blah' })]
    end

    it 'includes an "id" field' do
      expect(result['id']).to eq ['12345']
    end

    it 'includes an "marcxml_marcxml" field' do
      expect(result['marcxml_marcxml'].first).to include('<record>')
    end
  end

  context 'with a best bet record' do
    let(:fields) do
      [marc_control_field(tag: '001', value: '9979746730903681')]
    end

    it 'includes a best_bet_queries_sim field' do
      expect(result['best_bet_queries_sim']).to eq(['atlantic', 'atlantic monthly', 'the atlantic',
                                                    'the atlantic monthly'])
    end

    it 'does not set title suggester fields' do
      expect(result).not_to have_key('main_title_title_suggest')
      expect(result).not_to have_key('title_suggest_weight_is')
    end
  end
end
