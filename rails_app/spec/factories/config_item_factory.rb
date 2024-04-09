# frozen_string_literal: true

FactoryBot.define do
  factory :config_item do
    trait :boolean do
      name { 'boolean_config' }
      value { false }
      config_type { ConfigItem::BOOLEAN_TYPE }
    end
    trait :array do
      name { 'array_config' }
      value { %w[one two] }
      config_type { ConfigItem::ARRAY_TYPE }
    end
    trait :string do
      name { 'string_config' }
      value { 'value' }
      config_type { ConfigItem::STRING_TYPE }
    end
  end
end
