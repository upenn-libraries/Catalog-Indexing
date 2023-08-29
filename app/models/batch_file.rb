# frozen_string_literal: true

# Represent a constituent file from a completed Alma publishing job containing a batch of xml records
class BatchFile < ApplicationRecord
  include Statuses

  belongs_to :publish_job

  validates :status, inclusion: Statuses::ALL, presence: true
  validates :path, presence: true
end
