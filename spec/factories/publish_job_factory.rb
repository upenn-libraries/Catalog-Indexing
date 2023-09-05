# frozen_string_literal: true

FactoryBot.define do
  factory :publish_job do
    target_collections { ['test-collection'] }
    status { Statuses::PENDING }
    alma_source { PublishJob::Sources::PRODUCTION }
    full { true }
    webhook_body { {} }

    factory :publish_job_with_files do
      transient do
        files_count { 2 }
      end
      batch_files do
        Array.new(files_count) { association(:batch_file) }
      end
    end
  end
end
