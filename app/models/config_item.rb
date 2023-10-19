# frozen_string_literal: true

# Represent a config value stored in the database
class ConfigItem < ApplicationRecord
  LIST = {
    process_bib_webhooks: { type: :boolean, default: false },
    webhook_target_collections: { type: :array, default: Array.wrap(Solr::Config.new.collection_name) },
  }.freeze
end
