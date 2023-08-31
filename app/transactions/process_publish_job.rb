# frozen_string_literal: true

require 'dry/transaction'

# Initialize and create a PublishJob from a webhook body. Downloads all files from SFTP and enqueues jobs to
# process BatchFiles
class ProcessPublishJob
  include Dry::Transaction(container: Container)

  step :initialize_publish_job
  step :download_all_files
  step :create_batch_files
  step :enqueue_batch_file_jobs
  step :update_publish_job

  # @param [String] webhook_body
  # @return [Dry::Monads::Result]
  def initialize_publish_job(webhook_body:)
    parsed_webhook_body = JSON.parse(webhook_body)
    publish_job = create_publish_job(webhook_body, parsed_webhook_body.dig('job_instance', 'submitted_by', 'desc'))
    unless (files_date = parsed_webhook_body.dig('job_instance', 'status_date'))
      Failure("Problem getting status date from webhook response for PublishJob ##{publish_job.id}")
    end

    Success(publish_job: publish_job, files_date: files_date)
  rescue JSON::JSONError => e
    Failure("Problem parsing webhook response: #{e.message}")
  rescue ActiveRecord::RecordInvalid => e
    Failure("Invalid PublishJob attributes: #{e.message}")
  end

  # @param [PublishJob] publish_job
  # @param [String] files_date
  # @return [Dry::Monads::Result]
  def download_all_files(publish_job:, files_date:, sftp_client: Sftp::Client.new)
    status_date = DateTime.parse(files_date)
    files_prefix = "all_ub_ah_b_#{status_date.strftime('%Y%m%d')}*.xml.tar.gz" # make prefix configurable
    sftp_files = sftp_client.download_all matching: files_prefix

    return Failure("No files downloaded from SFTP server using glob: #{files_prefix}") unless sftp_files.any?

    Success(publish_job: publish_job, sftp_files: sftp_files)
  rescue Sftp::Client::Error => e
    Failure("Problem retrieving files from SFTP server: #{e.message}")
  end

  # @param [PublishJob] publish_job
  # @param [Array<Sftp::File>] sftp_files
  # @return [Dry::Monads::Result]
  def create_batch_files(publish_job:, sftp_files:)
    batch_files = sftp_files.map do |ftp_file|
      BatchFile.create!(
        publish_job_id: publish_job.id,
        path: ftp_file.local_path,
        status: Statuses::PENDING
      )
    rescue StandardError => e
      # Notify -> problem with batch file preparation: #{e.message}, store notice on publish_job? fail job?
      next
    end
    Success(publish_job: publish_job, batch_files: batch_files)
  end

  # @param [PublishJob] publish_job
  # @param [Array<BatchFile>] batch_files
  # @return [Dry::Monads::Result]
  def enqueue_batch_file_jobs(publish_job:, batch_files:)
    batch_files.each_slice(500) do |slice|
      ProcessBulkFileJob.perform_bulk [slice.map(&:id)]
    end

    Success(publish_job: publish_job)
  end

  # @param [PublishJob] publish_job
  # @return [Dry::Monads::Result]
  def update_publish_job(publish_job:)
    publish_job.status = Statuses::IN_PROGRESS
    publish_job.save

    # Notify -> "PublishJob ##{publish_job.id} off and running!"

    Success(publish_job: publish_job)
  end

  private

  # @param [String] webhook_body
  # @param [String] job_submitter
  # @return [PublishJob]
  def create_publish_job(webhook_body, job_submitter)
    PublishJob.create!(status: Statuses::PENDING, started_at: Time.zone.now,
                       alma_source: PublishJob::Sources::PRODUCTION, webhook_body: webhook_body,
                       target_collections: Array.wrap(Solr::Config.new.collection_name),
                       initiated_by: job_submitter)
  end
end
