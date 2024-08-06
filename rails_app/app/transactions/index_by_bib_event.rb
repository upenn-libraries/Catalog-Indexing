# frozen_string_literal: true

require 'dry/transaction'

# Contains steps to index record received from bib created or updated webhook
class IndexByBibEvent
  include Dry::Transaction(container: Container)

  step :get_collections, with: 'webhooks.get_collections'
  step :commit_config
  step :prepare_marcxml, with: 'marcxml.prepare' # massage MARCXML
  step :prepare_writer
  step :index_via_traject, with: 'traject.index_records' # receive a IO object and do the indexing

  # Assemble commit-related params for Solr request to be handled by Traject
  # @option commit_within [String, Integer, NilClass] number of milliseconds
  # @option commit_on_close [Boolean] whether to issue commit after operation is complete
  # @return [Dry::Monads::Result]
  def commit_config(**args)
    commit_within = args[:commit_within] || Settings.solr.webhook_action_commit_within_time_ms
    commit_on_close = args[:commit_on_close] || false
    Success(commit_on_close: commit_on_close, commit_within: commit_within, **args)
  end

  # @param io [StringIO]
  # @return [Dry::Monads::Result]
  def prepare_writer(io:, collections:, commit_within:, commit_on_close:, **args)
    writer = MultiCollectionWriter.new(collections: collections, commit_within: commit_within,
                                       commit_on_close: commit_on_close)
    Success(io: io, writer: writer, indexer: PennMarcIndexer.new, **args)
  rescue StandardError => e
    Failure(exception: e)
  end
end
