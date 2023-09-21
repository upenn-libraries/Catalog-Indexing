# frozen_string_literal: true

module Steps
  # Step to index an IO stream via Traject
  class IndexRecords
    include Dry::Monads[:result]

    # @param [IO | StringIO] io
    # @param [Traject::Indexer] indexer
    # @return [Dry::Monads::Result]
    def call(io:, indexer: PennMarcIndexer.new, commit: false, **args)
      index_service = IndexingService.new(indexer: indexer, commit: commit)
      index_service.process(io: io)
      Success(errors: index_service.error_messages, **args)
    rescue IndexingService::FailuresExceededError => e
      Success(errors: index_service.error_messages.unshift(e.message), **args)
    rescue StandardError => e
      Failure("Failure while indexing: #{e.message}")
    end
  end
end

class IndexingService
  attr_accessor :error_messages

  class FailuresExceededError < StandardError; end

  def initialize(indexer: PennMarcIndexer.new, commit: false)
    @indexer = indexer
    @writer = MultiCollectionWriter.new(indexer.settings.merge({ 'solr_writer.commit_on_close' => commit }))
    @error_messages = []
    @skipped_count = 0
  end

  def process(io:)
    @indexer.process_with(MARC::XMLReader.new(io, parser: :nokogiri, ignore_namespace: true), @writer,
                          close_writer: true, on_skipped: skipped_proc, rescue_with: rescue_proc)
  end

  def rescue_proc
    @rescue_proc ||= proc do |context, exception|
      error_messages << "Error during record processing (ID: #{context.source_record_id}): #{exception.message}"
      raise FailuresExceededError, "Failed record count exceeds limit (#{max_failed})" if too_many_failed?
    end
  end

  def skipped_proc
    @skipped_proc ||= proc do |context|
      @skipped_count += 1
      error_messages << "Record skipped: #{context.record_inspect}"
      raise FailuresExceededError, "Skipped record count exceeds limit (#{max_skipped})." if too_many_skipped?
    end
  end

  private

  def too_many_skipped?
    @skipped_count >= max_skipped
  end

  def too_many_failed?
    @error_messages.length >= max_failed
  end

  def max_skipped
    @max_skipped ||= (@indexer.settings[:skipped_record_limit] || 0)
  end

  def max_failed
    @max_failed ||= (@indexer.settings[:failed_record_limit] || 0)
  end
end
