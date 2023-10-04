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
  step :prepare_indexer
  step :decompress_file
  step :index_records, with: 'traject.index_records'
  step :clean_up
  step :check_alma_export

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

  # @param [BatchFile] batch_file
  # @returns [Dry::Monads::Result]
  def validate_batch_file(batch_file:, **args)
    unless batch_file.status == Statuses::PENDING
      return handle_failure(
        batch_file, "BatchFile ##{batch_file.id} is in #{batch_file.status} state. It must be in 'pending' state."
      )
    end

    # check for presence of file
    unless File.exist?(batch_file.path)
      return handle_failure batch_file, "BatchFile expects a file present at #{batch_file.path}, but no file is present."
    end

    Success(batch_file: batch_file, **args)
  end

  # @param [BatchFile] batch_file
  # @returns [Dry::Monads::Result]
  def set_as_begun(batch_file:, **args)
    batch_file.update!({ started_at: Time.zone.now, status: Statuses::IN_PROGRESS })
    Success(batch_file: batch_file, **args)
  rescue StandardError => e
    handle_failure batch_file, "Unhandled error when updating batch file ##{batch_file.id}: #{e}"
  end

  # @param [BatchFile] batch_file
  # @returns [Dry::Monads::Result]
  def prepare_indexer(batch_file:, **args)
    settings = { 'solr_writer.target_collections' => batch_file.alma_export.target_collections,
                 'skipped_record_limit' => 500, 'failed_record_limit' => 100 }
    indexer = PennMarcIndexer.new(settings)
    Success(batch_file: batch_file, indexer: indexer, **args)
  end

  # @param [BatchFile] batch_file
  # @param [Traject::Indexer] indexer
  # @returns [Dry::Monads::Result]
  def decompress_file(batch_file:, indexer:, **args)
    file = File.open(batch_file.path) # leave file handle open so indexer can stream contents, cleanup in later step
    tar = Zlib::GzipReader.new(file)
    io = Gem::Package::TarReader.new(tar).first

    Success(io: io, indexer: indexer, file_handle: file, batch_file: batch_file, **args)
  rescue StandardError => e
    handle_failure batch_file, "Problem decompressing BatchFile: #{e.message}"
  end

  # Indexer Step

  # @param [BatchFile] batch_file
  # @param [File] file_handle
  # @param [Array<String>] errors
  # @returns [Dry::Monads::Result]
  def clean_up(batch_file:, file_handle:, errors:, **args)
    file_handle.close
    batch_file.update!({
                         error_messages: errors,
                         status: (errors.any? ? Statuses::COMPLETED_WITH_ERRORS : Statuses::COMPLETED),
                         completed_at: Time.zone.now
                       })
    # remove file?
    Success(batch_file: batch_file, **args)
  rescue StandardError => e
    handle_failure batch_file, "Problem updating BatchFile after indexing: #{e.message}"
  end

  # @param [BatchFile] batch_file
  # @returns [Dry::Monads::Result]
  def check_alma_export(batch_file:)
    benchmark = Benchmark.measure do
      batch_file.alma_export.set_completion_status! if batch_file.alma_export.all_batch_files_finished?
    end
    Rails.logger.info { "AlmaExport status check took #{benchmark.total} seconds (from BatchFile ##{batch_file.id}" }
    message = "All done with BatchFile #{batch_file.id} / #{batch_file.path}"
    Rails.logger.info { message }
    Success(message)
  end

  private

  # @param [BatchFile] batch_file
  # @param [String] message
  # @return [Dry::Monads::Failure]
  def handle_failure(batch_file, message)
    Rails.logger.info { "Batch file processing failed for ##{batch_file.id} @ #{batch_file.path}: #{message}" }
    mark_batch_file_failed(batch_file, message)
    Failure(message)
  end

  # @param [BatchFile] batch_file
  # @param [Array<String>, String] error_messages
  # @return [Boolean]
  def mark_batch_file_failed(batch_file, error_messages)
    batch_file.status = Statuses::FAILED
    batch_file.error_messages += Array.wrap(error_messages)
    batch_file.save
  end
end
