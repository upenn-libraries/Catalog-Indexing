# frozen_string_literal: true

# Index to Solr with MMS IDs, via Alma API and Traject
class PublishJobProcessJob
  include Sidekiq::Job

  # @param [String] webhook_body
  def perform(webhook_body)

    # parse webhook
    parsed_webhook_body = JSON.parse(webhook_body)

    # build out publish - step
    publish = PublishJob.create(
      status: PublishJob::Statuses::PENDING,
      alma_source: PublishJob::Sources::PRODUCTION, # TODO: how to know if sandbox? somehow in the webhook body?
      webhook_body: webhook_body,
      started_at: Time.zone.now,
      target_collections: Array.wrap(Solr::Config.collection_name), # TODO: how to know if otherwise? or multiple? e.g., ConfigService.full_dump_target_collections
      initiated_by: parsed_webhook_body.dig('job_instance', 'submitted_by', 'desc')
    )

    # download all files with prefix (derived from date) - step
    status_date = DateTime.parse(parsed_webhook_body.dig('job_instance', 'status_date'))
    files_prefix = "all_ub_ah_b_#{status_date.strftime('%Y%m%d')}*"
    ftp_files = Sftp::Client.download_all matching: files_prefix

    # build out BatchFiles - step
    batch_files = ftp_files.map do |ftp_file|
      BatchFile.create(
        publish_job_id: publish.id,
        path: ftp_file.local_path,
        status: BatchFile::Statuses::PENDING
      )
    end

    # enqueue batch files in bulk - use tee
    batch_files.each_slice(500) do |slice|
      ProcessBulkFile.perform_bulk slice.map(&:id) # TODO: create ProcessBulkFile
    end

  end
end
