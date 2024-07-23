# frozen_string_literal: true

module Steps
  module AlmaExport
    # Step to update an AlmaExport
    class Update
      include Dry::Monads[:result]
      include Support::ErrorHandling

      # Update AlmaExport record with in progress or invalidity details
      # @param alma_export [::AlmaExport]
      # @param collections [Array]
      # @param batch_job [Sidekiq::Batch]
      # @return [Dry::Monads::Result]
      def call(alma_export:, collections:, batch_job:, **args)
        alma_export.target_collections = Array.wrap collections
        alma_export.status = Statuses::IN_PROGRESS
        alma_export.started_at = Time.zone.now
        alma_export.batch_job_bid = batch_job.bid
        alma_export.save!
        SendSlackNotificationJob.perform_async("AlmaExport ##{alma_export.id}: off and running!")
        Success(alma_export: alma_export, batch_job: batch_job, **args)
      rescue StandardError => e
        reset_and_handle_error(alma_export, e)
      end

      private

      # @param alma_export [::AlmaExport]
      # @param exception [Exception]
      def reset_and_handle_error(alma_export, exception)
        validation_messages = alma_export.errors&.full_messages&.to_sentence
        alma_export.reload # reload AlmaExport to resolve any issues from attributes set above so we can save
        message = "Update failed with #{exception.class.name}: #{exception.message}."
        message += " Validation errors: #{validation_messages}" if validation_messages.present?
        handle_failure(alma_export, message)
      end
    end
  end
end
