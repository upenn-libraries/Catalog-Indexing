# frozen_string_literal: true

# Remove from Solr via ID (MMS ID)
class DeleteByIdentifierJob < TransactionJob
  sidekiq_options queue: 'high'

  # @param [String] id
  def transaction(id)
    DeleteByIdentifier.new.call(id: id)
  end
end
