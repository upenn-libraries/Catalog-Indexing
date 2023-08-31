# frozen_string_literal: true

# Process a BulkFile through the indexer
class ProcessBulkFileJob
  include Sidekiq::Job

  # @param [Integer] bulk_file_id
  def perform(bulk_file_id)
    # ProcessBulkFile.call(bulk_file_id)
  end
end
