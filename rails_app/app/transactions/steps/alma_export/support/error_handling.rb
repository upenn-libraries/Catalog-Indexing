# frozen_string_literal: true

module Steps
  module AlmaExport
    module Support
      # Methods supporting the handling and logging of critical and non-critical errors during AlmaExport processing
      # transactions.
      module ErrorHandling
        # @param [::AlmaExport] alma_export
        # @param [String] message
        # @return [Dry::Monads::Failure]
        def handle_failure(alma_export, message)
          Rails.logger.error { "Alma export processing failed for ##{alma_export.id}: #{message}" }
          SendSlackNotificationJob.perform_async("AlmaExport ##{alma_export.id}: Failed with message: #{message}")
          mark_as_failed(alma_export, message)
          Failure(message)
        end

        # @param [::AlmaExport] alma_export
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
    end
  end
end
