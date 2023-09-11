# frozen_string_literal: true

module Steps
  # Step to index an IO stream via Traject
  class IndexRecords
    include Dry::Monads[:result]

    # @param [IO | StringIO] io
    # @param [Traject::Indexer] indexer
    # @return [Dry::Monads::Result]
    def call(io:, indexer: PennMarcIndexer.new, **args)
      indexer.process_with(
        MARC::XMLReader.new(io, parser: :nokogiri, ignore_namespace: true),
        CatalogWriter.new(indexer.settings),
        close_writer: true
      )
      Success(**args)
    rescue StandardError => e
      Failure("Failure while indexing: #{e.message}")
    end
  end
end
