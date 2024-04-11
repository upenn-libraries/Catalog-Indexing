# frozen_string_literal: true

require 'dry/transaction'

# Initialize and create a AlmaExport from a webhook body. Downloads all files from SFTP and enqueues jobs to
# process BatchFiles
class ProcessAlmaExport
  include Dry::Transaction(container: Container)

  step :load_alma_export
  step :initialize_sftp_session
  step :get_sftp_files
  step :prepare_solr_collection
  step :update_alma_export
  step :process_sftp_files

  # @param [String] alma_export_id
  # @return [Dry::Monads::Result]
  def load_alma_export(alma_export_id:)
    alma_export = AlmaExport.find alma_export_id
    unless alma_export.status == Statuses::PENDING
      return Failure("AlmaExport with ID #{alma_export_id} is in #{alma_export.status}. It must be in 'pending' state.")
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
  def get_sftp_files(alma_export:, sftp_session:)
    sftp_files = sftp_session.files matching: files_matching_regex(alma_export.alma_job_identifier)
    if sftp_files.empty?
      return Failure("No files downloaded for Alma publishing job with ID: #{alma_export.alma_job_identifier}")
    end

    Success(alma_export: alma_export, sftp_session: sftp_session, sftp_files: sftp_files)
  rescue Sftp::Client::Error => e
    Failure("Problem retrieving files from SFTP server: #{e.message}")
  end

  # @param [AlmaExport] alma_export
  # @return [Dry::Monads::Result]
  def prepare_solr_collection(alma_export:, **args)
    collection_name = SolrTools.new_collection_name
    if SolrTools.collection_exists?(collection_name)
      return Failure("Solr collection #{collection_name} already exists. Something is probably going wrong.")
    end

    SolrTools.create_collection(collection_name)
    Success(alma_export: alma_export, collection: collection_name, **args)
  rescue SolrTools::CommandError => e
    Failure("Could not create new Solr collection '#{collection_name}': #{e.message}.")
  end

  # Files are ready to process, update AlmaExport to IN_PROGRESS
  # @param [AlmaExport] alma_export
  # @return [Dry::Monads::Result]
  def update_alma_export(alma_export:, collection:, **args)
    alma_export.target_collections = Array.wrap collection
    alma_export.status = Statuses::IN_PROGRESS
    alma_export.started_at = Time.zone.now
    alma_export.save

    # Notify -> "AlmaExport ##{alma_export.id} off and running!"

    Success(alma_export: alma_export, **args)
  end

  # In batches, download files, build BatchFile objects and enqueue processing jobs
  # @param [AlmaExport] alma_export
  # @param [Sftp::Client] sftp_session
  # @param [Array<Sftp::File>] sftp_files
  # @return [Dry::Monads::Result]
  def process_sftp_files(alma_export:, sftp_session:, sftp_files:)
    sftp_files.each_slice(20) do |slice|
      downloads = slice.map { |file| sftp_session.download(file, wait: false) }
      downloads.each(&:wait) # SFTP downloads occur concurrently here
      build_and_enqueue_batch_files(alma_export, slice)
    end
    Success(alma_export: alma_export)
  rescue StandardError => e
    alma_export.status = Statuses::FAILED
    alma_export.save
    Failure("Problem processing SFTP file for Alma Export (ID: #{alma_export.id}): #{e.message}")
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
end
