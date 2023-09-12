# frozen_string_literal: true

FactoryBot.define do
  factory :alma_export do
    target_collections { ['test-collection'] }
    status { Statuses::PENDING }
    alma_source { AlmaExport::Sources::PRODUCTION }
    full { true }
    webhook_body do
      { 'job_instance' => {
        'id' => '12345678'
      } }
    end

    trait :finished do
      started_at { 1.hour.ago }
      completed_at { Time.zone.now }
    end

    trait :started do
      started_at { 1.hour.ago }
    end

    trait(:failed) { status { Statuses::FAILED } }
    trait(:completed) { status { Statuses::COMPLETED } }
    trait(:completed_with_errors) { status { Statuses::COMPLETED_WITH_ERRORS } }
    trait(:in_progress) { status { Statuses::IN_PROGRESS } }
    trait(:pending) { status { Statuses::PENDING } }

    factory :alma_export_with_files do
      transient do
        files_count { 2 }
      end
      batch_files do
        Array.new(files_count) { association(:batch_file) }
      end
    end

    trait :with_files_some_failed do
      batch_files do
        [association(:batch_file, :finished, :failed),
         association(:batch_file, :finished, :completed),
         association(:batch_file, :finished, :completed_with_errors)]
      end
    end

    trait :with_files_all_failed do
      batch_files do
        [association(:batch_file, :finished, :failed),
         association(:batch_file, :finished, :failed)]
      end
    end

    trait :with_files_all_completed do
      batch_files do
        [association(:batch_file, :finished, :completed),
         association(:batch_file, :finished, :completed)]
      end
    end

    trait :with_files_all_incomplete do
      batch_files do
        [association(:batch_file, :finished, :pending),
         association(:batch_file, :finished, :in_progress)]
      end
    end
  end
end
