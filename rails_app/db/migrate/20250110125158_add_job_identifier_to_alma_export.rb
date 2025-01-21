# frozen_string_literal: true

# Add an explicit job_identifier field, replacing methods that extract it from the webhook_body
class AddJobIdentifierToAlmaExport < ActiveRecord::Migration[7.1]
  def change
    add_column :alma_exports, :job_identifier, :string
  end
end
