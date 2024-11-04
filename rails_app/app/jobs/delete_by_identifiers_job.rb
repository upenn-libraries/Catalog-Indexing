# frozen_string_literal: true

# Remove from Solr via ID (MMS ID)
class DeleteByIdentifiersJob < TransactionJob
  sidekiq_options queue: 'high'

  # @param [String] ids
  def transaction(ids)
    DeleteByIdentifier.new.call(ids: ids)
  end
end
