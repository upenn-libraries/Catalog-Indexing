# frozen_string_literal: true

# Add a Sidekiq::Batch ID field to the AlmaExport so we can query for it's status
class AddBatchJobIdToAlmaExport < ActiveRecord::Migration[7.1]
  def change
    change_table :alma_exports, bulk: true do |t|
      t.integer :batch_job_bid
    end
  end
end
