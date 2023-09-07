# frozen_string_literal: true

# Represent a completed Export from Alma. Alma Exports have a 1:1 relation to the running of an Alma Publishing job.
# This entity contains information about the job and information about the target Solr collections for the indexing of
# the exported records.
class AlmaExport < ApplicationRecord
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
