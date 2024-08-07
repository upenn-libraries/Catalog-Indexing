# frozen_string_literal: true

describe ProcessBatchFile do
  let(:transaction) { described_class.new }

  describe '#call' do
    let(:outcome) { transaction.call(batch_file_id: batch_file.id, commit_within: 0) }

    context 'with a bad BatchFile ID' do
      let(:batch_file) { instance_double(BatchFile) }

      before { allow(batch_file).to receive(:id).and_return(1) }

      it 'returns a Failure monad with the appropriate message' do
        expect(outcome).to be_failure
        expect(outcome.failure[:message]).to include 'record with ID 1 does not exist'
      end
    end

    context 'with invalid BatchFile status' do
      let(:batch_file) { create(:batch_file, :in_progress) }

      it 'returns a Failure monad with the appropriate message' do
        expect(outcome).to be_failure
        expect(outcome.failure[:message]).to include "BatchFile ##{batch_file.id} is in #{batch_file.status} state"
      end

      it 'sets the status of the BatchFile to failed and stores the failure message' do
        outcome
        batch_file.reload
        expect(batch_file.status).to eq Statuses::FAILED
        expect(batch_file.error_messages.join).to include "It must be in 'pending' state"
      end
    end

    context 'with a BatchFile that has no corresponding file on the filesystem' do
      let(:batch_file) { create(:batch_file) }

      it 'returns a Failure monad with the appropriate message' do
        expect(outcome).to be_failure
        expect(outcome.failure[:message]).to include "expects a file present at #{batch_file.path}"
      end
    end

    context 'with a problem during file decompression' do
      let(:batch_file) { create(:batch_file, :with_empty_file) }

      it 'returns a Failure monad with the appropriate message' do
        expect(outcome).to be_failure
        expect(outcome.failure[:message]).to include 'Problem decompressing BatchFile'
      end
    end
  end
end
