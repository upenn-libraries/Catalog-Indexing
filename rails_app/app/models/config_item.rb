# frozen_string_literal: true

# Represent a config value stored in the database. Values are stores as a Postgres JSON type so anything that can be
# represented in JSON is a potential value. Currently only Boolean, String and Array types are supported. While complex
# value objects would be supported, building out form elements to set those values would be complicated. The overarching
# point of this class is to allow some configuration parameters to be altered via the UI, not via environment variable
# or other build-time settings.
#
# See config_item_helper.rb for helpers that render form partials for these value types. See the rake task for
# tools:add_config_items to set initial values in the database for the configuration items depended upon by the app.
class ConfigItem < ApplicationRecord
  BOOLEAN_TYPE = 'boolean'
  ARRAY_TYPE = 'array'
  STRING_TYPE = 'string'

  VALID_TYPES = [ARRAY_TYPE, BOOLEAN_TYPE, STRING_TYPE].freeze

  validates :name, presence: true, uniqueness: true
  validates :config_type, presence: true, inclusion: { in: VALID_TYPES, message: 'must be a supported type' }
  validates :value, inclusion: { in: [true, false], message: 'must be boolean', if: :boolean? }

  # Return value from database by name.
  #
  # @param name [String, Symbol] name of ConfigItem value
  # @raise [ArgumentError] if config item matching name is not found
  # @return [Object] configured value of config item
  def self.value_for(name, detail_config: details)
    raise ArgumentError, "ConfigItem is not available: #{name}" unless detail_config.key? name.to_sym

    config_item = ConfigItem.find_by(name: name)
    raise StandardError, "Config Item is not initialized for #{name}" unless config_item

    config_item.value
  end

  # controlled list of config entries, default value(s) and options. "default" is used when first initializing
  # the entries. "options_method" is used when rendering the form to provide a list of permitted values, and should
  # correspond to a rails helper method.
  # @note we don't want to memoize this because we always want the latest Solr collection list
  # @return [Hash]
  def self.details
    solr_collections = SolrTools.collections
    {
      process_job_webhooks: { default: false },
      process_bib_webhooks: { default: false },
      webhook_target_collections: { default: [], options: solr_collections },
      adhoc_target_collections: { default: [], options: solr_collections }
    }
  end

  private

  # @return [Boolean]
  def boolean?
    config_type == BOOLEAN_TYPE
  end
end
