# frozen_string_literal: true

# Represent a config value stored in the database
class ConfigItem < ApplicationRecord
  validates :name, uniqueness: true
  validates :value, inclusion: { in: [true, false], message: 'must be boolean' }, if: :boolean_type?

  BOOLEAN_TYPE = :boolean
  ARRAY_TYPE = :array
  STRING_TYPE = :string

  VALID_TYPES = [ARRAY_TYPE, BOOLEAN_TYPE, STRING_TYPE].freeze

  # controlled list of config entries, their type and default value
  LIST = {
    process_job_webhooks: { type: BOOLEAN_TYPE, default: false },
    process_bib_webhooks: { type: BOOLEAN_TYPE, default: false },
    webhook_target_collections: {
      type: ARRAY_TYPE, default: Array.wrap(Solr::Config.new.collection_name),
      options_method: :available_collections
    }
    # alias targets?
  }.freeze

  # Return value from database by name, or default from config
  # @param [String|Symbol] name
  # @raise [ArgumentError] if config item matching name is not found
  # @return [Object] configured value of config item
  def self.value_for(name)
    raise ArgumentError, "ConfigItem is not available: #{name}" unless ConfigItem::LIST[name]

    ConfigItem.find_by(name: name)&.value || ConfigItem::LIST.dig(name, :default)
  end

  def value_type
    ConfigItem::LIST[name.to_sym][:type]
  end

  private

  def boolean_type?
    value_type == BOOLEAN_TYPE
  end
end
