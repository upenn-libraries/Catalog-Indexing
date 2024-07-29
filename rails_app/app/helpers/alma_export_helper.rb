# frozen_string_literal: true

# AlmaExport helper methods
module AlmaExportHelper
  # @param number [Integer]
  # @param total [Integer]
  # @return [String]
  def status_percentage(number, total)
    pct = (number.to_f / total) * 100
    number_to_percentage(pct, precision: 0)
  end
end
