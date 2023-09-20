# frozen_string_literal: true

require 'dry/transaction'
require 'rubygems/package'

# Initialize and create a AlmaExport from a webhook body. Downloads all files from SFTP and enqueues jobs to
# process BatchFiles
class ProcessBatchFile
  include Dry::Transaction(container: Container)

  step :load_batch_file
  step :validate_batch_file
  step :prepare_indexer
  step :decompress_file
  step :index_records, with: 'traject.index_records'
  step :clean_up
  step :check_alma_export

  # @param [String] batch_file_id
  # @return [Dry::Monads::Result]
  def load_batch_file(batch_file_id:, **args)
    batch_file = BatchFile.find batch_file_id
    Success(batch_file: batch_file, **args)
  rescue ActiveRecord::RecordNotFound => _e
    Failure("BatchFile record with ID #{batch_file_id} does not exist.")
  end

  # @param [BatchFile] batch_file
  # @returns [Dry::Monads::Result]
  def validate_batch_file(batch_file:, **args)
    unless batch_file.status == Statuses::PENDING
      return Failure("BatchFile with ID #{batch_file.id} is in #{batch_file.status} state. It must be in 'pending' state.")
    end

    # check for presence of file
    unless File.exist?(batch_file.path)
      return Failure("BatchFile expects a file present at #{batch_file.path}, but no file is present.")
    end

    batch_file.update_column(:started_at, Time.zone.now) # sends raw UPDATE query, no validations/callbacks

    Success(batch_file: batch_file, **args)
  end

  # @param [BatchFile] batch_file
  def prepare_indexer(batch_file:, **args)
    settings = { 'solr_writer.target_collections' => batch_file.alma_export.target_collections } # TODO: target_collections should be validated in the ProcessAlmaExport transaction/job
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
    Failure("Problem decompressing BatchFile: #{e.message}")
  end

  # Indexer Step...
  # TODO: how to rescue/record errors from indexer step that should not stop processing? Consider custom Yell logger?

  # @param [BatchFile] batch_file
  # @param [File] file_handle
  # @returns [Dry::Monads::Result]
  def clean_up(batch_file:, file_handle:, **args)
    file_handle.close
    batch_file.status = Statuses::COMPLETED
    batch_file.completed_at = Time.zone.now
    batch_file.save
    # remove file? decompressed contents?
    Success(batch_file: batch_file, **args)
  rescue StandardError => e
    Failure("Problem updating BatchFile after indexing: #{e.message}")
  end

  # @param [BatchFile] batch_file
  # @returns [Dry::Monads::Result]
  def check_alma_export(batch_file:)
    batch_file.alma_export.set_completion_status! if batch_file.alma_export.all_batch_files_finished?
    Success("All done with BatchFile #{batch_file.id} / #{batch_file.path}")
  end

  private

  # @param [BatchFile] batch_file
  # @param [Array<String>, String] error_messages
  # @return [Boolean]
  def mark_batch_file_failed(batch_file, error_messages)
    batch_file.status = Statuses::FAILED
    batch_file.error_messages.merge Array.wrap(error_messages) # TODO: will this merge work?
    batch_file.save
  end
end
