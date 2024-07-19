# frozen_string_literal: true

require 'dry/transaction'
require 'rubygems/package'

# Handle AlmaExport processing for an incremental publish. Downloads all files from SFTP and enqueues jobs to
# process BatchFiles and deletes.
# ID for example use: 59711274490003681
class ProcessIncrementalAlmaExport
  SFTP_PARALLEL_DOWNLOADS = 20

  include Dry::Transaction(container: Container)

  step :load_alma_export
  step :initialize_sftp_session
  step :get_sftp_files_list
  step :validate_target_collections
  step :update_alma_export
  step :accumulate_ids_for_deletion
  step :delete_from_solr
  step :prepare_batch_job
  step :process_published_files

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
    Success(alma_export: alma_export, sftp_session: sftp_session, sftp_files: sftp_files)
  rescue Sftp::Client::Error => e
    Failure("Problem retrieving files from SFTP server: #{e.message}")
  rescue StandardError => e
    handle_error alma_export, "Unexpected error (#{e.class.name}) during SFTP list: #{e.message}"
  end

  def validate_target_collections(**args)
    collections = ConfigItem.value_for :incremental_target_collections
    return Failure('No incremental target collections configured.') if collections.empty?

    collections.each do |collection|
      unless SolrTools.collection_exists? collection
        return Failure("Configured incremental target collection '#{collection}' does not exist.")
      end
    end

    Success(alma_export: args[:alma_export], collections: collections, sftp_session:args[:sftp_session0], **args)
  end

  # Files are ready to process, update AlmaExport to IN_PROGRESS
  # @param [AlmaExport] alma_export
  # @param [Sftp::Client] sftp_session
  # @return [Dry::Monads::Result]
  def update_alma_export(alma_export:, collections:, sftp_session:, **args)
    alma_export.target_collections = collections
    alma_export.status = Statuses::IN_PROGRESS
    alma_export.started_at = Time.zone.now
    alma_export.save!
    SendSlackNotificationJob.perform_async("AlmaExport ##{alma_export.id}: off and running!")
    Success(alma_export: alma_export, sftp_session: sftp_session, **args)
  rescue StandardError => e
    validation_messages = alma_export.errors&.full_messages&.to_sentence
    alma_export.reload # reload AlmaExport to resolve any issues from attributes set above so we can save
    message = "Update failed with #{e.class.name}: #{e.message}."
    message += " Validation errors: #{validation_messages}" if validation_messages.present?
    handle_failure(alma_export, message)
  end

  # Download, read and extract MMS IDs for deleted records from _delete file(s)
  # @param [AlmaExport] alma_export
  # @param [Sftp::Client] sftp_session
  # @return [Dry::Monads::Result]
  def accumulate_ids_for_deletion(alma_export:, sftp_session:, **args)
    delete_files = sftp_session.files matching: files_matching_regex(alma_export.alma_job_identifier, deletes: true)
    return Success(alma_export: alma_export, ids: [], **args) if delete_files.empty?

    # TODO: will there always only be a single deleted file?
    #       should i spin this off as it's own job? batch?
    ids = []
    delete_files.each do |delete_file|
      _wat = sftp_session.download(delete_file)
      file = File.open(delete_file.local_path)
      tar = Zlib::GzipReader.new(file)
      io = Gem::Package::TarReader.new(tar).first
      records = MARC::XMLReader.new(io, parser: :nokogiri, ignore_namespace: true)
      ids << records.map { |r| r['001'].value }
    end
    ids = ids.flatten.uniq
    Success(alma_export: alma_export, ids: ids, **args)
  end

  # Issue deletes to Solr for configured collections, using IDs provided
  # @param [AlmaExport] alma_export
  # @param [Array] ids
  # @return [Dry::Monads::Result]
  def delete_from_solr(alma_export:, ids:, **args)
    return Success(alma_export: alma_export, **args) if ids.empty?

    solrs = alma_export.target_collections.map { |collection| Solr::QueryClient.new(collection: collection) }
    solrs.each do |solr|
      response = solr.delete id: ids
      raise StandardError, "Unable to delete records from Solr collection #{solr.collection}" unless response.response[:status] == 200
    end
    # Slack notification? "XXX records processed for deletion from __collection__"
    Success(alma_export: alma_export, **args)
  rescue StandardError => e # TODO: use a bespoke exception
    handle_failure alma_export, e.message
  end

  # Initialize a Sidekiq::Batch we can use to process the add/update files
  # @param [AlmaExport] alma_export
  # @return [Dry::Monads::Result]
  def prepare_batch_job(alma_export:, **args)
    batch_job = Sidekiq::Batch.new
    batch_job.description = "Incremental add/update jobs for AlmaExport #{alma_export.id}."
    batch_job.on(:success, ::BatchCallbacks::FinalizeAlmaExport, 'alma_export_id' => alma_export.id) # all constituent jobs succeed
    batch_job.on(:complete, ::BatchCallbacks::FinalizeAlmaExport, 'alma_export_id' => alma_export.id) # all constituent jobs have run
    Success(alma_export: alma_export, batch_job: batch_job, **args)
  end

  # In batches, download files, build BatchFile objects and enqueue processing jobs
  # @param [AlmaExport] alma_export
  # @param [Array<Sftp::File>] sftp_files
  # @param [Sidekiq::Batch] batch_job
  # @return [Dry::Monads::Result]
  def process_published_files(alma_export:, sftp_files:, batch_job:, **args)
    sftp_files.each_slice(SFTP_PARALLEL_DOWNLOADS) do |slice|
      sftp_session = Sftp::Client.new # initialize a new connection each batch to avoid connection being closed
      downloads = slice.map { |file| sftp_session.download(file, wait: false) }
      downloads.each(&:wait) # SFTP downloads occur concurrently here
      sftp_session.close_channel # close connection since we open a new once each iteration
      build_and_enqueue_batch_files(alma_export, batch_job, slice)
    end
    SendSlackNotificationJob.perform_async("AlmaExport ##{alma_export.id}: All #{sftp_files.count} files downloaded.")
    Success(alma_export: alma_export, **args)
  rescue StandardError => e
    message = "Error #{e.class.name} processing SFTP file: #{e.message}."
    handle_failure(alma_export, message)
  end

  # Return a regex suitable for matching only the output files of the specified PUBLISH job
  # See Alma Publishing profile for filename schema
  # @param [String] alma_job_identifier
  # @param deletes [Boolean] whether to list _delete files. otherwise only _new files will be listed
  # @return [Regexp]
  def files_matching_regex(alma_job_identifier, deletes: false)
    if deletes
      /_#{alma_job_identifier}_.*_delete.tar.gz/
    else
      /_#{alma_job_identifier}_.*_new_\d+.tar.gz/
    end
  end

  private

  # @param [AlmaExport] alma_export
  # @param [Sidekiq::Batch] batch_job
  # @param [Array<Sftp::File>] sftp_files
  def build_and_enqueue_batch_files(alma_export, batch_job, sftp_files)
    batch_files = sftp_files.map do |sftp_file|
      BatchFile.create!(alma_export_id: alma_export.id, path: sftp_file.local_path,
                        status: Statuses::PENDING)
    end
    # TODO: this executes the batch!
    batch_job.jobs do
      Sidekiq::Client.push_bulk('class' => ProcessBatchFileJob, 'args' => batch_files.map { |bf| [bf.id] })
    end
    bid = batch.bid
    # TODO: add bid to AlmaExport record? is it set before .jobs? we need it to monitor/report on batch status/outcome.
  end

  # @param [AlmaExport] alma_export
  # @param [String] message
  # @return [Dry::Monads::Failure]
  def handle_failure(alma_export, message)
    Rails.logger.error { "Alma export processing failed for ##{alma_export.id}: #{message}" }
    SendSlackNotificationJob.perform_async("AlmaExport ##{alma_export.id}: Failed with message: #{message}")
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
