# frozen_string_literal: true

# Process a BatchFile through the indexer
class ProcessBatchFileJob < TransactionJob
  # @param [Integer] batch_file_id
  def transaction(batch_file_id)
    ProcessBatchFile.new.call(batch_file_id: batch_file_id)
  end
end
