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
end
