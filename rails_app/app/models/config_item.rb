# frozen_string_literal: true

# Represent a config value stored in the database
class ConfigItem < ApplicationRecord
  BOOLEAN_TYPE = 'boolean'
  ARRAY_TYPE = 'array'
  STRING_TYPE = 'string'

  VALID_TYPES = [ARRAY_TYPE, BOOLEAN_TYPE, STRING_TYPE].freeze

  # controlled list of config entries, default value(s) and options. "default" is used when first initializing
  # the entries. "options_method" is used when rendering the form to provide a list of permitted values, and should
  # correspond to a rails helper method.
  DETAILS = {
    process_job_webhooks: { default: false },
    process_bib_webhooks: { default: false },
    webhook_target_collections: {
      default: Array.wrap(Solr::Config.new.collection_name),
      options_method: :available_collections
    }
  }.freeze

  validates :name, presence: true, uniqueness: true
  validates :config_type, presence: true, inclusion: { in: VALID_TYPES, message: 'must be a supported type' }
  validates :value, inclusion: { in: [true, false], message: 'must be boolean', if: :boolean? }

  # Return value from database by name, or default from config
  # @param name [String|Symbol] name of ConfigItem value
  # @raise [ArgumentError] if config item matching name is not found
  # @return [Object] configured value of config item
  def self.value_for(name, details: DETAILS)
    raise ArgumentError, "ConfigItem is not available: #{name}" unless details.key? name.to_sym

    config_item = ConfigItem.find_by(name: name)
    raise StandardError, "Config Item is not initialized for #{name}" unless config_item

    config_item.value
  end

  private

  def boolean?
    config_type == BOOLEAN_TYPE
  end
end
