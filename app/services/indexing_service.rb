# frozen_string_literal: true

# Wrap up usage of Traject Indexer to write to Solr
# Receives IO and a configured Indexer, traject does the rest
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
