# frozen_string_literal: true

describe Steps::PrepareMARCXML do
  include FixtureHelpers

  let(:sample_mmsid) { '9979201969103681' }
  let(:marcxml) { marc_fixture sample_mmsid }
  let(:step) { described_class.new }

  describe '#call' do
    let(:result) { step.call(docs: marcxml) }

    it 'returns a success monad' do
      expect(result).to be_success
    end

    it 'returns a StringIO encoded in UTF-8' do
      expect(result.success[:io]).to be_a StringIO
      expect(result.success[:io].read.encoding.name).to eq 'UTF-8'
    end
  end
end
