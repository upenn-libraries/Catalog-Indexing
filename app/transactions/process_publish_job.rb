# frozen_string_literal: true

require 'dry/transaction'

# Initialize and create a PublishJob from a webhook body. Downloads all files from SFTP and enqueues jobs to
# process BatchFiles
class ProcessPublishJob
  include Dry::Transaction(container: Container)

  step :initialize_publish_job
  step :initialize_sftp_session
  step :get_sftp_files
  step :update_publish_job
  step :process_sftp_files

  # @param [String] webhook_body
  # @return [Dry::Monads::Result]
  def initialize_publish_job(webhook_body:)
    webhook_data = JSON.parse webhook_body
    publish_job = PublishJob.create!(status: Statuses::PENDING, started_at: Time.zone.now,
                                     alma_source: PublishJob::Sources::PRODUCTION, webhook_body: webhook_data,
                                     target_collections: Array.wrap(Solr::Config.new.collection_name))
    Success(publish_job: publish_job)
  rescue JSON::JSONError => e
    Failure("Problem parsing webhook response: #{e.message}")
  rescue ActiveRecord::RecordInvalid => e
    Failure("Invalid PublishJob attributes: #{e.message}")
  end

  # @param [PublishJob] publish_job
  def initialize_sftp_session(publish_job:)
    sftp_session = Sftp::Client.new
    Success(publish_job: publish_job, sftp_session: sftp_session)
  rescue Sftp::Client::Error => e
    Failure("Problem connecting to the SFTP server: #{e.message}")
  end

  # get Sftp::File objects via dir entries/glob
  # @param [PublishJob] publish_job
  # @param [Sftp::Client] sftp_session
  # @return [Dry::Monads::Result]
  def get_sftp_files(publish_job:, sftp_session:)
    sftp_files = sftp_session.files matching: files_matching_regex(publish_job.alma_job_identifier)
    if sftp_files.empty?
      return Failure("No files downloaded for Alma Publishing job with ID: #{publish_job.alma_job_identifier}")
    end

    Success(publish_job: publish_job, sftp_session: sftp_session, sftp_files: sftp_files)
  rescue Sftp::Client::Error => e
    Failure("Problem retrieving files from SFTP server: #{e.message}")
  end

  # Files are ready to process, update PublishJob to IN_PROGRESS
  # @todo use AASM instead?
  # @param [PublishJob] publish_job
  # @param [Sftp::Client] sftp_session
  # @param [Array<Sftp::File>] sftp_files
  # @return [Dry::Monads::Result]
  def update_publish_job(publish_job:, sftp_session:, sftp_files:)
    publish_job.status = Statuses::IN_PROGRESS
    publish_job.save

    # Notify -> "PublishJob ##{publish_job.id} off and running!"

    Success(publish_job: publish_job, sftp_session: sftp_session, sftp_files: sftp_files)
  end

  # In batches, download files, build BatchFile objects and enqueue processing jobs
  # @param [PublishJob] publish_job
  # @param [Sftp::Client] sftp_session
  # @param [Array<Sftp::File>] sftp_files
  # @return [Dry::Monads::Result]
  def process_sftp_files(publish_job:, sftp_session:, sftp_files:)
    sftp_files.each_slice(20) do |slice|
      downloads = slice.map { |file| sftp_session.download(file, wait: false) }
      downloads.each(&:wait) # SFTP downloads occur concurrently here
      build_and_enqueue_build_files(publish_job, slice)
    end
    Success(publish_job: publish_job)
  rescue StandardError => e
    publish_job.status = Statuses::FAILED # TODO: how would this be done with AASM?
    publish_job.save
    Failure("Problem processing SFTP file for Publish Job (ID: #{publish_job.id}): #{e.message}")
  end

  # Return a regex suitable for matching only the output files of the specified FULL PUBLISH job
  # @param [String] alma_job_identifier
  # @return [Regexp]
  def files_matching_regex(alma_job_identifier)
    /_#{alma_job_identifier}_new_\d+.xml.tar.gz/
  end

  private

  # @param [PublishJob] publish_job
  # @param [Array<Sftp::File>] sftp_files
  def build_and_enqueue_build_files(publish_job, sftp_files)
    batch_file_jobs_params = sftp_files.map do |sftp_file|
      batch_file = BatchFile.create!(publish_job_id: publish_job.id, path: sftp_file.local_path,
                                     status: Statuses::PENDING)
      Array.wrap(batch_file.id)
    end
    ProcessBatchFileJob.perform_bulk(batch_file_jobs_params)
  end
end
