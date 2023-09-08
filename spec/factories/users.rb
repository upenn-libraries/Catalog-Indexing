# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    transient do
      identifier { 'developer@library.upenn.edu' }
    end
    provider { 'test' }
    uid { identifier }
    email { identifier }
  end
end
