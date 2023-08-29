# frozen_string_literal: true

# Represent a Publishing Job (from Alma)
class AddPublishJob < ActiveRecord::Migration[7.0]
  def change
    create_table :publish_jobs do |t|
      t.string :target_collections, array: true, default: []
      t.string :status
      t.string :alma_source
      t.string :initiated_by
      t.boolean :full, default: true, null: false
      t.text :webhook_body
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps
    end
  end
end
