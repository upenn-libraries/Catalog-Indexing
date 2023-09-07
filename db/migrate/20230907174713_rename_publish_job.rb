# frozen_string_literal: true

# rename PublishJob model to AlmaExport, and update name of corresponding FK field in BatchFile
class RenamePublishJob < ActiveRecord::Migration[7.0]
  def change
    rename_table :publish_jobs, :alma_exports
    rename_column :batch_files, :publish_job_id, :alma_export_id
  end
end
