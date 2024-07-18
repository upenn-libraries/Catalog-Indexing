# frozen_string_literal: true

require 'dry/transaction'
require 'rubygems/package'

# Looks up a BatchFile, validates, decompresses and processes contents through PennMarcIndexer. Checks up on AlmaExport
# completion status at the end.
class ProcessBatchFile
  include Dry::Transaction(container: Container)

  step :load_batch_file
  step :validate_batch_file
  step :set_as_begun
  step :prepare_writer
  step :decompress_file
  step :index_records, with: 'traject.index_records'
  step :clean_up
  step :check_alma_export

  # Load the BatchFile
  # @param [String] batch_file_id
  # @return [Dry::Monads::Result]
  def load_batch_file(batch_file_id:, **args)
    batch_file = BatchFile.find batch_file_id
    Rails.logger.info { "Batch file processing beginning for ID ##{batch_file_id} @ #{batch_file.path}." }
    Success(batch_file: batch_file, **args)
  rescue ActiveRecord::RecordNotFound => _e
    message = "BatchFile record with ID #{batch_file_id} does not exist."
    Rails.logger.info { "BatchFile processing failed: #{message}" }
    Failure(message)
  end

  # Perform some checks to help ensure BatchFile is ready to be processed
  # @param [BatchFile] batch_file
  # @return [Dry::Monads::Result]
  def validate_batch_file(batch_file:, **args)
    unless batch_file.status == Statuses::PENDING
      return handle_failure(
        batch_file, "BatchFile ##{batch_file.id} is in #{batch_file.status} state. It must be in 'pending' state."
      )
    end

    # check for presence of file
    unless File.exist?(batch_file.path)
      return handle_failure(batch_file,
                            "BatchFile expects a file present at #{batch_file.path}, but no file is present.")
    end

    Success(batch_file: batch_file, **args)
  end

  # Update BatchFile status
  # @param [BatchFile] batch_file
  # @return [Dry::Monads::Result]
  def set_as_begun(batch_file:, **args)
    batch_file.update!({ started_at: Time.zone.now, status: Statuses::IN_PROGRESS })
    Success(batch_file: batch_file, **args)
  rescue StandardError => e
    handle_failure batch_file, "Unhandled error when updating batch file ##{batch_file.id}: #{e}"
  end

  # Prepare Traject indexer, apply configuration
  # @param [BatchFile] batch_file
  # @return [Dry::Monads::Result]
  def prepare_writer(batch_file:, **args)
    settings = { 'skipped_record_limit' => 500, 'failed_record_limit' => 100 }
    writer = MultiCollectionWriter.new(collections: batch_file.alma_export.target_collections,
                                       settings: settings,
                                       commit_within: args.delete(:commit_within))
    Success(batch_file: batch_file, writer: writer, **args)
  end

  # Prepare reader for compressed file
  # @param [BatchFile] batch_file
  # @param [Traject::Writer] writer
  # @return [Dry::Monads::Result]
  def decompress_file(batch_file:, writer:, **args)
    file = File.open(batch_file.path) # leave file handle open so indexer can stream contents, cleanup in later step
    tar = Zlib::GzipReader.new(file)
    io = Gem::Package::TarReader.new(tar).first

    Success(io: io, writer: writer, file_handle: file, batch_file: batch_file, **args)
  rescue StandardError => e
    handle_failure batch_file, "Problem decompressing BatchFile: #{e.message}"
  end

  # Indexer Step

  # After indexing completes, update the BatchFile status and clean up
  # @todo clean up any files from the file system at this time?
  # @todo can we distinguish between "completion with errors" and "failure" based on the response of the indexing step?
  #       if the skip/error limits are exceeded, should that be considered a failure?
  # @param [BatchFile] batch_file
  # @param [File] file_handle
  # @param [Array<String>] errors
  # @return [Dry::Monads::Result]
  def clean_up(batch_file:, file_handle:, errors:, **args)
    file_handle.close
    batch_file.update!({ error_messages: errors, completed_at: Time.zone.now,
                         status: (errors.any? ? Statuses::COMPLETED_WITH_ERRORS : Statuses::COMPLETED) })
    # remove file?
    Success(batch_file: batch_file, **args)
  rescue StandardError => e
    handle_failure batch_file, "Problem updating BatchFile after indexing: #{e.message}"
  end

  # Check if all BatchFiles for the current AlmaExport are in a completed state, and update the AlmaExport status if
  # needed.
  # @note this may be subject to a race condition when jobs are processed in parallel
  # @todo this should be replaced with Sidekiq Pro's batching system when available
  # @param [BatchFile] batch_file
  # @return [Dry::Monads::Result]
  def check_alma_export(batch_file:, **)
    message = "All done with BatchFile #{batch_file.id} / #{batch_file.path}"
    return Success(message) unless batch_file.alma_export.full

    benchmark = Benchmark.measure { should_complete_alma_export(batch_file) }
    Rails.logger.info { "AlmaExport status check took #{benchmark.total} seconds (from BatchFile ##{batch_file.id})" }
    Rails.logger.info { message }
    Success(message)
  rescue StandardError => e
    handle_failure batch_file, "Problem checking AlmaExport after BatchFile ##{batch_file.id} completion: #{e.message}"
  end

  private

  # @param [BatchFile] batch_file
  def should_complete_alma_export(batch_file)
    return unless batch_file.alma_export.all_batch_files_finished?

    batch_file.alma_export.set_completion_status!
    SendSlackNotificationJob.perform_async("AlmaExport ##{batch_file.alma_export.id} file processing completed!")
    issue_solr_commits(alma_export: batch_file.alma_export)
    Rails.logger.info do
      "AlmaExport ##{batch_file.alma_export.id} marked complete after BatchFile ##{batch_file.id} processed."
    end
  end

  # @param [BatchFile] batch_file
  # @param [String] message
  # @return [Dry::Monads::Failure]
  def handle_failure(batch_file, message)
    Rails.logger.error { "Batch file processing failed for ##{batch_file.id} @ #{batch_file.path}: #{message}" }
    mark_as_failed(batch_file, message)
    Failure(message)
  end

  # @param [BatchFile] batch_file
  # @param [Array<String>, String] error_messages
  # @return [Boolean]
  def mark_as_failed(batch_file, error_messages)
    batch_file.status = Statuses::FAILED
    batch_file.error_messages += Array.wrap(error_messages)
    batch_file.save!
  rescue StandardError => e
    Rails.logger.error do
      "Unexpected error trying to update BatchFile ##{batch_file.id} upon processing error: #{e.message}"
    end
  end

  # @param [AlmaExport] alma_export
  def issue_solr_commits(alma_export:)
    benchmark = Benchmark.measure do
      alma_export.target_collections.each do |collection|
        Solr::QueryClient.new(collection: collection).commit
      end
    end
    SendSlackNotificationJob.perform_async(
      "AlmaExport ##{alma_export.id}: Solr commits to #{alma_export.target_collections.to_sentence} completed " \
        " in #{benchmark.total} seconds."
    )
  end
end
