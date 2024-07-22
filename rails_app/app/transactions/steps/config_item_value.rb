# frozen_string_literal: true

module Steps
  # Step to grab a ConfigItem value by name
  class ConfigItemValue
    include Dry::Monads[:result]

    # Grab a ConfigItem value and return as config_value
    # @param config_item_name [String|Symbol] collections to validate
    # @return [Dry::Monads::Result]
    def call(config_item_name:, **args)
      value = ConfigItem.value_for config_item_name
      return Failure("No ConfigItem value established for #{config_item_name}") if value.blank?

      Success(config_value: value, **args)
    end
  end
end
