# frozen_string_literal: true

FactoryBot.define do
  factory :batch_file do
    alma_export
    path { 'all_ub_ah_b_20000101_123456789_new_001.xml.tar.gz' }
    status { Statuses::PENDING }
  end
end
