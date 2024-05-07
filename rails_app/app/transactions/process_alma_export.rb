# frozen_string_literal: true

require 'dry/transaction'

# Initialize and create a AlmaExport from a webhook body. Downloads all files from SFTP and enqueues jobs to
# process BatchFiles
class ProcessAlmaExport
  SFTP_PARALLEL_DOWNLOADS = 20

  include Dry::Transaction(container: Container)

  step :load_alma_export
  step :initialize_sftp_session
  step :get_sftp_files_list
  step :prepare_solr_collection
  step :update_alma_export
  step :process_sftp_files

  # @param [String] alma_export_id
  # @return [Dry::Monads::Result]
  def load_alma_export(alma_export_id:)
    alma_export = AlmaExport.find alma_export_id
    unless alma_export.status == Statuses::PENDING
      return handle_failure(
        alma_export,
        "AlmaExport with ID #{alma_export_id} is in #{alma_export.status}. It must be in 'pending' state."
      )
    end

    Success(alma_export: alma_export)
  rescue ActiveRecord::RecordNotFound => _e
    Failure("AlmaExport record with ID #{alma_export_id} does not exist.")
  end

  # @param [AlmaExport] alma_export
  # @return [Dry::Monads::Result]
  def initialize_sftp_session(alma_export:)
    sftp_session = Sftp::Client.new
    Success(alma_export: alma_export, sftp_session: sftp_session)
  rescue Sftp::Client::Error => e
    Failure("Problem connecting to the SFTP server: #{e.message}")
  end

  # get Sftp::File objects via SFTP entries
  # @param [AlmaExport] alma_export
  # @param [Sftp::Client] sftp_session
  # @return [Dry::Monads::Result]
  def get_sftp_files_list(alma_export:, sftp_session:)
    sftp_files = sftp_session.files matching: files_matching_regex(alma_export.alma_job_identifier)
    if sftp_files.empty?
      return handle_failure(
        alma_export,
        "No files downloaded for Alma publishing job with ID: #{alma_export.alma_job_identifier}"
      )
    end

    Rails.logger.info { "Sftp files found for this AlmaExport: #{sftp_files.count}." }
    Success(alma_export: alma_export, sftp_files: sftp_files)
  rescue Sftp::Client::Error => e
    Failure("Problem retrieving files from SFTP server: #{e.message}")
  rescue StandardError => e
    handle_error alma_export, "Unexpected error (#{e.class.name}) during SFTP list: #{e.message}"
  end

  # @param [AlmaExport] alma_export
  # @return [Dry::Monads::Result]
  def prepare_solr_collection(alma_export:, **args)
    collection_name = SolrTools.new_collection_name
    if SolrTools.collection_exists?(collection_name)
      return handle_failure(alma_export,
                            "Solr collection #{collection_name} already exists. Something is going wrong.")
    end

    SolrTools.create_collection(collection_name)
    Success(alma_export: alma_export, collection: collection_name, **args)
  rescue SolrTools::CommandError => e
    handle_failure(alma_export, "Could not create new Solr collection '#{collection_name}': #{e.message}.")
  rescue StandardError => e
    handle_failure alma_export, "Unexpected error (#{e.class.name}) during Solr prep: #{e.message}"
  end

  # Files are ready to process, update AlmaExport to IN_PROGRESS
  # @param [AlmaExport] alma_export
  # @return [Dry::Monads::Result]
  def update_alma_export(alma_export:, collection:, **args)
    alma_export.target_collections = Array.wrap collection
    alma_export.status = Statuses::IN_PROGRESS
    alma_export.started_at = Time.zone.now
    alma_export.save!
    SendSlackNotificationJob.perform_async("AlmaExport ##{alma_export.id} off and running!")
    Success(alma_export: alma_export, **args)
  rescue StandardError => e
    validation_messages = alma_export.errors&.full_messages&.to_sentence
    alma_export.reload # reload AlmaExport to resolve any issues from attributes set above so we can save
    message = "Update failed with #{e.class.name}: #{e.message}."
    message += " Validation errors: #{validation_messages}" if validation_messages.present?
    handle_failure(alma_export, message)
  end

  # In batches, download files, build BatchFile objects and enqueue processing jobs
  # @param [AlmaExport] alma_export
  # @param [Array<Sftp::File>] sftp_files
  # @return [Dry::Monads::Result]
  def process_sftp_files(alma_export:, sftp_files:)
    sftp_files.each_slice(SFTP_PARALLEL_DOWNLOADS) do |slice|
      sftp_session = Sftp::Client.new # initialize a new connection each batch to avoid connection being closed
      downloads = slice.map { |file| sftp_session.download(file, wait: false) }
      downloads.each(&:wait) # SFTP downloads occur concurrently here
      sftp_session.close_channel # close connection since we open a new once each iteration
      build_and_enqueue_batch_files(alma_export, slice)
    end
    Success(alma_export: alma_export)
  rescue StandardError => e
    message = "Error #{e.class.name} processing SFTP file: #{e.message}."
    handle_failure(alma_export, message)
  end

  # Return a regex suitable for matching only the output files of the specified FULL PUBLISH job
  # @param [String] alma_job_identifier
  # @return [Regexp]
  def files_matching_regex(alma_job_identifier)
    /_#{alma_job_identifier}_new_\d+.xml.tar.gz/
  end

  private

  # @param [AlmaExport] alma_export
  # @param [Array<Sftp::File>] sftp_files
  def build_and_enqueue_batch_files(alma_export, sftp_files)
    batch_file_jobs_params = sftp_files.map do |sftp_file|
      batch_file = BatchFile.create!(alma_export_id: alma_export.id, path: sftp_file.local_path,
                                     status: Statuses::PENDING)
      Array.wrap(batch_file.id)
    end
    ProcessBatchFileJob.perform_bulk(batch_file_jobs_params)
  end

  # @param [AlmaExport] alma_export
  # @param [String] message
  # @return [Dry::Monads::Failure]
  def handle_failure(alma_export, message)
    Rails.logger.error { "Alma export processing failed for ##{alma_export.id}: #{message}" }
    mark_as_failed(alma_export, message)
    Failure(message)
  end

  # @param [AlmaExport] alma_export
  # @param [Array<String>, String] error_messages
  # @return [Boolean]
  def mark_as_failed(alma_export, error_messages)
    alma_export.status = Statuses::FAILED
    alma_export.error_messages += Array.wrap(error_messages)
    alma_export.save!
  rescue StandardError => e
    Rails.logger.error do
      "Unexpected error trying to update AlmaExport ##{alma_export.id} upon processing error: #{e.message}"
    end
  end
end
