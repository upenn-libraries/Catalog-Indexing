# frozen_string_literal: true

module Steps
  # Step to index an IO stream via Traject
  class IndexRecords
    include Dry::Monads[:result]

    # @param [IO | StringIO] io
    # @param [Traject::Indexer] indexer
    # @param [Boolean] commit
    # @return [Dry::Monads::Result]
    def call(io:, indexer: PennMarcIndexer.new, commit: false, **args)
      index_service = IndexingService.new(indexer: indexer, commit: commit)
      index_service.process(io: io)
      Success(errors: index_service.error_messages, **args)
    rescue IndexingService::FailuresExceededError, IndexingService::SkipsExceededError => e
      # We return success here even though a limit has been exceeded and expect that later processing steps will
      # act based on the returned errors accordingly
      Success(errors: (index_service&.error_messages&.unshift(e.message) || [e.message]), **args)
    rescue StandardError => e
      Failure("Failure while indexing: #{e.message}")
    end
  end
end
