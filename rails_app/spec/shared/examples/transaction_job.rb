# frozen_string_literal: true

shared_examples_for 'TransactionJob' do
  let(:job) { described_class.new }

  before do
    raise 'arguments must be set with `let(:args)`' unless defined? args
  end

  describe '#transaction' do
    it 'implements #transaction method' do
      expect(job).to respond_to(:transaction)
    end

    it 'returns a Result object' do
      expect(job.transaction(*args)).to be_a Dry::Monads::Result
    end
  end

  describe '#perform' do
    context 'when transaction returns a failure' do
      context 'with a message only' do
        before do
          allow(job).to receive(:transaction).with(*args)
                                             .and_return(Dry::Monads::Failure.new(message: 'Oh no something happened'))
        end

        it 'raises an exception' do
          expect { job.perform(*args) }.to raise_error StandardError, 'Oh no something happened'
        end
      end

      context 'with an exception' do
        let(:exception) do
          StandardError.new 'Something went wrong!'
        end

        before do
          allow(job).to receive(:transaction).with(*args)
                                             .and_return(Dry::Monads::Failure.new(error: :error, exception: exception))
        end

        it 'raises an exception' do
          expect { job.perform(*args) }.to raise_error exception
        end
      end
    end
  end
end
