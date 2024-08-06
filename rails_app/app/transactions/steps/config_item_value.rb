# frozen_string_literal: true

module Steps
  # Step to grab a ConfigItem value by name
  class ConfigItemValue
    include Dry::Monads[:result]

    # @param name [String, Symbol] name of ConfigItem to lookup
    # @param as [String, Symbol] parameter name to use in response
    def initialize(name: nil, as: :config_value)
      @name = name&.to_sym
      @as = as.to_sym
    end

    # Grab a ConfigItem value and return as config_value
    # @return [Dry::Monads::Result]
    def call(args)
      name = args.delete(:config_item_name) || @name
      value = ConfigItem.value_for name
      return Failure(message: "No ConfigItem value established for #{name}") if value.blank?

      Success(@as => value, **args)
    end
  end
end
