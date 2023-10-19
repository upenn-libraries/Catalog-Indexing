# frozen_string_literal: true

# Service methods for reading ConfigItem values and returning the expected data type, considering a default value if no
# configuration value is set.
module ConfigService
  class << self
    # @return [Boolean]
    def process_bib_webhooks?
      config_value_or_default :process_bib_webhooks
    end

    # @return [Array<String>]
    def webhook_target_collections
      config_value_or_default :webhook_target_collections
    end

    private

    # @param [Symbol] config_name
    def config_value_or_default(config_name)
      raise ArgumentError, "ConfigItem is not available: #{config_name}" unless ConfigItem::LIST[config_name]

      ConfigItem.find_by(name: config_name)&.value || ConfigItem::LIST.dig(config_name, :default)
    end
  end
end
