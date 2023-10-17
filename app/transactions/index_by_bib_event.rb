# frozen_string_literal: true

require 'dry/transaction'

# Contains steps to index record received from bib created or updated webhook
class IndexByBibEvent
  include Dry::Transaction(container: Container)

  step :prepare_marcxml, with: 'prepare_marcxml' # massage MARCXML - for now ensure UTF-8
  step :prepare_writer_and_indexer
  step :index_via_traject, with: 'traject.index_records' # receive a IO object and do the indexing

  def prepare_writer_and_indexer(io:, **args)
    target_collections = Array.wrap(Solr::Config.new.collection_name) # TODO: eventually pull this from settings, e.g., Settings.webhook_target_collections
    writer = MultiCollectionWriter.new({ 'solr_writer.target_collections' => target_collections })
    Success(io: io, writer: writer, indexer: PennMarcIndexer.new)
  rescue StandardError => e
    Failure("Problem preparing writer: #{e.message}")
  end
end
