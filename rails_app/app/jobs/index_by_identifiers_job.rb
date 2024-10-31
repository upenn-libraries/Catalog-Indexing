# frozen_string_literal: true

# Index to Solr with MMS IDs, via Alma API and Traject
class IndexByIdentifiersJob < TransactionJob
  sidekiq_options queue: 'high'

  # @param [Array] identifiers
  def transaction(identifiers)
    IndexByIdentifiers.new.call(identifiers: identifiers)
  end
end
