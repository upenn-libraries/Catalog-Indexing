# frozen_string_literal: true

module Steps
  class IndexRecords
    include Dry::Monads[:result]

    # @param [Array|String] records
    # @param [Traject::Indexer] indexer
    # @return [Traject::Writer]
    def call(io:, indexer: PennMarcIndexer.new)
      indexer.process_with(
        MARC::XMLReader.new(io, parser: :nokogiri, ignore_namespace: true),
        CatalogWriter.new(indexer.settings),
        close_writer: true
      )
      Success(true)
    rescue StandardError => e
      Failure(e)
    end
  end
end
