# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    provider { 'test' }
    uid { 'testuser' }
    email { 'testuser@example.com' }
    active { true }
  end

  trait :saml do
    provider { 'saml' }
  end

  trait :inactive do
    active { false }
  end
end
