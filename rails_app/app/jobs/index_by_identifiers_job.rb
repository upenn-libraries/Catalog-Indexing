# frozen_string_literal: true

# Index to Solr with MMS IDs, via Alma API and Traject
class IndexByIdentifiersJob
  include Sidekiq::Job

  sidekiq_options queue: 'high'

  # @param [Array] identifiers
  def perform(identifiers)
    IndexByIdentifier.new.call(identifiers: identifiers)
  end
end
