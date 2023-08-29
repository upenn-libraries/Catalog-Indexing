# frozen_string_literal: true

# Represent a Published File (from Alma)
class AddBatchFile < ActiveRecord::Migration[7.0]
  def change
    create_table :batch_files do |t|
      t.references :publish_job, foreign_key: true
      t.string :path
      t.string :status
      t.datetime :started_at
      t.datetime :completed_at
      t.string :error_messages, array: true, default: []
      t.timestamps
    end
  end
end
