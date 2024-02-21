# frozen_string_literal: true

# Represent a config value stored in the database
class ConfigItem < ApplicationRecord
  # controlled list of config entries, their type and default value
  LIST = {
    process_bib_webhooks: { type: :boolean, default: false },
    webhook_target_collections: { type: :array, default: Array.wrap(Solr::Config.new.collection_name) },
  }.freeze

  # Return value from database by name, or default from config
  # @param [String|Symbol] name
  # @raise [ArgumentError] if config item matching name is not found
  # @return [Object] configured value of config item
  def self.value_for(name)
    raise ArgumentError, "ConfigItem is not available: #{name}" unless ConfigItem::LIST[name]

    ConfigItem.find_by(name: name)&.value || ConfigItem::LIST.dig(name, :default)
  end
end
