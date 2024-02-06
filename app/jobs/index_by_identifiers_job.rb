# frozen_string_literal: true

# Index to Solr with MMS IDs, via Alma API and Traject
class IndexByIdentifiersJob < TransactionJob
  # @param [Array] identifiers
  def transaction(identifiers)
    IndexByIdentifier.new.call(identifiers: identifiers)
  end
end
