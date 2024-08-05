# frozen_string_literal: true

module BatchCallbacks
  # Sidekiq::Batch callbacks for use with AlmaExport processing jobs
  class FinalizeAlmaExport
    # @param _status [Sidekiq::Batch::Status]
    # @param alma_export_id [String]
    def on_success(_status, alma_export_id)
      alma_export = AlmaExport.find(alma_export_id)
      solrs = alma_export.target_collections.map { |collection| Solr::QueryClient.new(collection: collection) }
      solrs.each(&:commit)
      SendSlackNotificationJob.perform_async(
        "AlmaExport ##{alma_export.id}: Solr commits to #{alma_export.target_collections.to_sentence} completed."
      )
      # TODO: this might do nothing if some jobs aren't marked with a completed status
      alma_export.set_completion_status!
      # Move files?
    end

    # Executed when all jobs in the batch have run once, successful or not
    # @param status [Sidekiq::Batch::Status]
    # @param alma_export_id [String]
    def on_complete(status, alma_export_id)
      alma_export = AlmaExport.find(alma_export_id)
      SendSlackNotificationJob.perform_async("AlmaExport ##{alma_export.id}: All jobs executed.")
      return unless status.failure_info.any?

      SendSlackNotificationJob.perform_async(
        "AlmaExport ##{alma_export.id}: Job Failures: ```#{status.failure_info}```"
      )
    end
  end
end
