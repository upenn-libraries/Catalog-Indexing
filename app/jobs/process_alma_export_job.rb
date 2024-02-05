# frozen_string_literal: true

# Process an AlmaExport. See ProcessAlmaExport transaction for the interesting bits.
class ProcessAlmaExportJob < TransactionJob
  # @param [String] alma_export_id
  def transaction(alma_export_id)
    ProcessAlmaExport.new.call(alma_export_id: alma_export_id)
  end
end
