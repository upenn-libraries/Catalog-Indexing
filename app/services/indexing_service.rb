# frozen_string_literal: true

# Wrap up usage of Traject Indexer to write to Solr
# Receives IO and a configured Indexer, traject does the rest
class IndexingService
  attr_accessor :error_messages

  class FailuresExceededError < StandardError; end
  class SkipsExceededError < StandardError; end

  # Initialize Indexing service with an indexer. Settings from Indexer will be shared with writer.
  # @todo what id we need to use a different writer? wait for a use case to figure that out
  # @param [Traject::Indexer] indexer
  # @param [Boolean] commit after the indexer runs
  def initialize(indexer: PennMarcIndexer.new, commit: false)
    @indexer = indexer
    @writer = MultiCollectionWriter.new(indexer.settings.merge({ 'solr_writer.commit_on_close' => commit }))
    @error_messages = []
    @skipped_count = 0
  end

  # Process IO stream through indexer
  # @param [IO|StringIO] io
  # @return [MultiCollectionWriter]
  def process(io:)
    @indexer.process_with(MARC::XMLReader.new(io, parser: :nokogiri, ignore_namespace: true), @writer,
                          close_writer: true, on_skipped: skipped_proc, rescue_with: rescue_proc)
  end

  # Called when the indexer raises an exception while processing a record
  # @return [Proc]
  def rescue_proc
    @rescue_proc ||= proc do |context, exception|
      error_messages << compose_error_message(context, exception)
      raise FailuresExceededError, "Failed record count exceeds limit (#{max_failed})" if too_many_failed?
    end
  end

  # Called when the indexer skips a record
  # @return [Proc]
  def skipped_proc
    @skipped_proc ||= proc do |context|
      @skipped_count += 1
      error_messages << "Record skipped: #{context.record_inspect}"
      raise SkipsExceededError, "Skipped record count exceeds limit (#{max_skipped})." if too_many_skipped?
    end
  end

  private

  # @param [Traject::Indexer::Context] context
  # @param [Exception] exception
  # @return [String]
  def compose_error_message(context, exception)
    <<~MSG
      Unexpected error on record #{context.record_inspect} while executing #{context.index_step.inspect}.
      Exception #{exception.class.name}: #{exception.message}
      From: #{exception.backtrace.first}
    MSG
  end

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
