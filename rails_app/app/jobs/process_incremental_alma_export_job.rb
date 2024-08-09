# frozen_string_literal: true

# Process an "incremental" AlmaExport. See ProcessIncrementalAlmaExport transaction for the interesting bits.
class ProcessIncrementalAlmaExportJob < TransactionJob
  sidekiq_options queue: 'high'

  # @param alma_export_id [String]
  def transaction(alma_export_id)
    ProcessIncrementalAlmaExport.new.call(alma_export_id: alma_export_id)
  end
end
