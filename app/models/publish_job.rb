# frozen_string_literal: true

# Represent a completed Publish Job from Alma
class PublishJob < ApplicationRecord
  include Statuses

  module Sources
    PRODUCTION = 'production'
    SANDBOX = 'sandbox'
    ALL = [PRODUCTION, SANDBOX].freeze
  end

  has_many :batch_files, dependent: :destroy

  validates :alma_source, inclusion: Sources::ALL, presence: true
  validates :full, presence: true
  validates :webhook_body, presence: true

  # @return [String, nil]
  def alma_job_identifier
    webhook_body.dig('job_instance', 'id')
  end
end
