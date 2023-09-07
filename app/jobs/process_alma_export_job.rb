# frozen_string_literal: true

# Process an AlmaExport. See ProcessAlmaExport transaction for the interesting bits.
class ProcessAlmaExportJob
  include Sidekiq::Job

  # @param [String] alma_export_id
  def perform(alma_export_id)
    outcome = ProcessAlmaExport.new.call(alma_export_id: alma_export_id)
    outcome.success?
    # Notify based on failure outcomes?
  end
end
