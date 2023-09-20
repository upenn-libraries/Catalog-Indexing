# frozen_string_literal: true

module Steps
  # Step to index an IO stream via Traject
  class IndexRecords
    include Dry::Monads[:result]

    # @param [IO | StringIO] io
    # @param [Traject::Indexer] indexer
    # @return [Dry::Monads::Result]
    def call(io:, indexer: PennMarcIndexer.new, commit: false, **args)
      errors = []
      indexer.process_with(
        MARC::XMLReader.new(io, parser: :nokogiri, ignore_namespace: true),
        MultiCollectionWriter.new(indexer.settings.merge({ 'solr_writer.commit_on_close' => commit })),
        on_skipped: proc do |context|
          # TODO: track count of skipped records, and raise if reached?
          errors << "Record skipped: #{context.record_inspect}"
        end,
        rescue_with: proc do |context, exception|
          # TODO: we may want to raise certain exceptions. handling all exceptions with this proc will cause processing
          #       to continue when we might want it to stop (e.g., after a bunch of failures)
          errors << "Error during record processing (ID: #{context.source_record_id}): #{exception.message}"
        end,
        close_writer: true
      )
      Success(errors: errors, **args)
    rescue StandardError => e
      Failure("Failure while indexing: #{e.message}")
    end
  end
end
