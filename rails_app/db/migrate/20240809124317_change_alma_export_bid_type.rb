# frozen_string_literal: true

# Change AlmaExport bid field to string type from integer
class ChangeAlmaExportBidType < ActiveRecord::Migration[7.1]
  def up
    change_column :alma_exports, :bid, :string
  end

  # Not all Strings can be converted back to Integers. This could raise ActiveModel::RangeError and require data
  # cleanup. But we tend to never reverse migrations so I don't anticipate issues. Bid vales can be discarded if there
  # are issues.
  def down
    change_column :alma_exports, :bid, :integer
  end
end
