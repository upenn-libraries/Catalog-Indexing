# frozen_string_literal: true

require 'dry/transaction'

# Initialize and create a AlmaExport from a webhook body. Downloads all files from SFTP and enqueues jobs to
# process BatchFiles
class ProcessBatchFile
  include Dry::Transaction(container: Container)

  step :load_batch_file
  step :validate_batch_file
  step :prepare_indexer
  step :decompress_file
  step :index_records, from: 'traject.index_records'
  step :clean_up
  step :check_alma_export

  # @param [String] batch_file_id
  # @return [Dry::Monads::Result]
  def load_batch_file(batch_file_id:)
    batch_file = AlmaExport.find batch_file_id
    Success(batch_file: batch_file)
  rescue ActiveRecord::RecordNotFound => _e
    Failure("BatchFile record with ID #{batch_file_id} does not exist.")
  end

  # @param [BatchFile] batch_file
  # @returns [Dry::Monads::Result]
  def validate_batch_file(batch_file:)
    unless batch_file.status == Statuses::PENDING
      return Failure("BatchFile with ID #{batch_file_id} is in #{batch_file.status}. It must be in 'pending' state.")
    end

    # check for presence of file
    unless File.exist?(batch_file.path)
      return Failure("BatchFile expects a file present at #{batch_file.path}, but no file is present.")
    end

    batch_file.update_column(:started_at, Time.zone.now) # sends raw UPDATE query, no validations/callbacks

    Success(batch_file: batch_file)
  end

  def prepare_indexer(batch_file:)
    alma_export = batch_file.alma_export # for target_collections...
    indexer = PennMarcIndexer.new # TODO: specify settings (target collection(s), etc.) different from those defined in the indexer itself?

    Success(batch_file: batch_file, indexer: indexer)
  end

  # @param [BatchFile] batch_file
  # @returns [Dry::Monads::Result]
  def decompress_file(batch_file:, indexer:, **args)
    io = File.open(batch_file.path) do |file|
      tar = Zlib::GzipReader.new(file)
      Gem::Package::TarReader.new(tar).first
    end

    Success(io: io, indexer: indexer, **args)
  rescue StandardError => e
    Failure("Problem decompressing BatchFile: #{e.message}")
  end

  # Indexer Step...
  # TODO: how to configure indexer step to write to > 1 collection? use a modified writer class?
  # TODO: how to rescue/record errors from indexer step that should not stop processing? Consider custom Yell logger?

  # @param [BatchFile] batch_file
  # @returns [Dry::Monads::Result]
  def clean_up(batch_file:, **args)
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
    # are all child BatchFiles for the parent AlmaExport in a completed status?
    # if no, exit
    # if yes, update status for AlmaExport, maybe do some other stuff
    if batch_file.alma_export.all_batch_files_finished? # TODO: build model method
      batch_file.alma_export.set_completion_status! # TODO: build model method
    end
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
