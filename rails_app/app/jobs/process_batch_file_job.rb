# frozen_string_literal: true

# Process a BatchFile through the indexer
class ProcessBatchFileJob < TransactionJob
  sidekiq_options queue: 'low'

  # @param [Integer] batch_file_id
  def transaction(batch_file_id)
    ProcessBatchFile.new.call(batch_file_id: batch_file_id)
  end
end
