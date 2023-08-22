# frozen_string_literal: true

describe Steps::IndexRecords do
  include FixtureHelpers

  let(:marcxml) { marc_fixture '9979201969103681' }
  let(:io) { StringIO.new(marcxml) }

  describe '#call' do
    let(:step) { described_class.new }

    context 'with invalid IO' do
      it 'returns failure monad' do
        expect(step.call(io: [666])).to be_failure
      end
    end

    context 'with a good IO' do
      it 'returns success monad' do
        expect(step.call(io: io)).to be_success
      end
    end
  end
end