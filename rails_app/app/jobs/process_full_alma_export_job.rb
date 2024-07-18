# frozen_string_literal: true

# Process a "full" AlmaExport. See ProcessFullAlmaExport transaction for the interesting bits.
class ProcessFullAlmaExportJob < TransactionJob
  sidekiq_options queue: 'high'

  # @param [String] alma_export_id
  def transaction(alma_export_id)
    ProcessFullAlmaExport.new.call(alma_export_id: alma_export_id)
  end
end
