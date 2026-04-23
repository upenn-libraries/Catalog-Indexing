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
      enqueue_suggester_builds(alma_export)
      # TODO: this might do nothing if some jobs aren't marked with a completed status
      alma_export.set_completion_status!
    end

    # Executed when all jobs in the batch have run once, successful or not
    # @param status [Sidekiq::Batch::Status]
    # @param alma_export_id [String]
    def on_complete(status, alma_export_id)
      alma_export = AlmaExport.find(alma_export_id)
      SendSlackNotificationJob.perform_async("AlmaExport ##{alma_export.id}: All jobs executed.")
      return unless status.failed_jids.any?

      SendSlackNotificationJob.perform_async(
        "AlmaExport ##{alma_export.id}: Job Failure IDs: ```#{status.failed_jids}```"
      )
    end

    private

    # After an indexing operation is complete, rebuild these suggesters
    # @param alma_export [AlmaExport]
    def enqueue_suggester_builds(alma_export)
      enqueue_title_suggester_build(alma_export)
    end

    # Build the title suggester if configured to do so
    # @param alma_export [AlmaExport]
    def enqueue_title_suggester_build(alma_export)
      return unless build_title_suggester?(alma_export)

      BuildTitleSuggestDictionaryJob.perform_async
    end

    # Whether the title suggester should be rebuilt for the given export
    # @param alma_export [AlmaExport]
    # @return [Boolean]
    def build_title_suggester?(alma_export)
      settings = Settings.suggester.title
      return settings.build_after_full if alma_export.full?

      settings.build_after_incremental
    end
  end
end
