# frozen_string_literal: true

module Steps
  module AlmaExport
    # Step to lookup and AlmaExport
    class Find
      include Dry::Monads[:result]
      include Support::ErrorHandling

      # Lookup AlmaExport
      # @param alma_export_id [String]
      # @return [Dry::Monads::Result]
      def call(alma_export_id:, **args)
        alma_export = ::AlmaExport.find alma_export_id
        unless alma_export.status == Statuses::PENDING
          return handle_failure(
            alma_export,
            "AlmaExport with ID #{alma_export_id} is in #{alma_export.status}. It must be in 'pending' state."
          )
        end

        Success(alma_export: alma_export, **args)
      rescue ActiveRecord::RecordNotFound => _e
        Failure(message: "AlmaExport record with ID #{alma_export_id} does not exist.")
      end
    end
  end
end
