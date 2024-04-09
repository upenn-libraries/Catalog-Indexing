# frozen_string_literal: true

require 'dry/transaction'

# Contains steps to index record received from bib created or updated webhook
class IndexByBibEvent
  include Dry::Transaction(container: Container)

  step :prepare_marcxml, with: 'marcxml.prepare' # massage MARCXML
  step :prepare_writer
  step :index_via_traject, with: 'traject.index_records' # receive a IO object and do the indexing

  def prepare_writer(io:, **args)
    target_collections = Array.wrap(ConfigItem.value_for(:webhook_target_collections))
    writer = MultiCollectionWriter.new({ 'solr_writer.target_collections' => target_collections })
    Success(io: io, writer: writer, indexer: PennMarcIndexer.new, **args)
  rescue StandardError => e
    Failure("Problem preparing writer: #{e.message}")
  end
end
