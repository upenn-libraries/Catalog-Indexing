# frozen_string_literal: true

# replace webhook body field with a JSON object field and remove initiated_by field, as we can query the JSON field for
# that data
class ChangePublishJobWebhookField < ActiveRecord::Migration[7.0]
  def change
    remove_column :publish_jobs, :initiated_by, :string
    remove_column :publish_jobs, :webhook_body, :text
    add_column :publish_jobs, :webhook_body, :jsonb
  end
end
