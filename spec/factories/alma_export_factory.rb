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

    factory :alma_export_with_files do
      transient do
        files_count { 2 }
      end

      after(:create) do |alma_export, evaluator|
        FactoryBot.create_list(:batch_file, evaluator.files_count, alma_export: alma_export)
      end
    end
  end
end
