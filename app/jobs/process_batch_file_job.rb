# frozen_string_literal: true

# Process a BatchFile through the indexer
class ProcessBatchFileJob
  include Sidekiq::Job

  # @param [Integer] batch_file_id
  def perform(batch_file_id)
    # ProcessBatchFile.call(batch_file_id)
  end
end
