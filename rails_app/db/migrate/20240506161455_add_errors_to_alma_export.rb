# frozen_string_literal: true

# Add fields to store errors happening at the AlmaExport level
class AddErrorsToAlmaExport < ActiveRecord::Migration[7.1]
  def change
    change_table 'alma_exports', bulk: true do |t|
      t.string :error_messages, array: true, default: []
    end
  end
end
