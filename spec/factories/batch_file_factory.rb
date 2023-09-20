# frozen_string_literal: true

FactoryBot.define do
  factory :batch_file do
    alma_export
    path { 'all_ub_ah_b_20000101_123456789_new_001.xml.tar.gz' }
    status { Statuses::PENDING }

    trait :finished do
      started_at { 1.hour.ago }
      completed_at { Time.zone.now }
    end

    trait :started do
      started_at { 1.hour.ago }
    end

    trait :with_empty_file do
      path { Rails.root.join('spec/fixtures/files/empty.xml.tar.gz') }
    end

    trait :with_two_record_file do
      path { Rails.root.join('spec/fixtures/files/two_record.xml.tar.gz') }
    end

    trait(:failed) { status { Statuses::FAILED } }
    trait(:completed) { status { Statuses::COMPLETED } }
    trait(:completed_with_errors) { status { Statuses::COMPLETED_WITH_ERRORS } }
    trait(:in_progress) { status { Statuses::IN_PROGRESS } }
    trait(:pending) { status { Statuses::PENDING } }
  end
end
