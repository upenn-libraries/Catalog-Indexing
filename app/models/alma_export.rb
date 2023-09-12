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

  # query to see if all associated BatchFiles are in a completed state (completed, completed with errors, failed)
  def all_batch_files_finished?
    all_unique_batch_file_statuses.none? { |status| status.in? Statuses::INCOMPLETE_STATUSES }
  end

  # set to appropriate completed status and save
  # @return [TrueClass]
  def set_completion_status!
    return unless all_batch_files_finished?

    new_status = if all_unique_batch_file_statuses == [Statuses::FAILED]
                   Statuses::FAILED
                 elsif all_unique_batch_file_statuses == [Statuses::COMPLETED]
                   Statuses::COMPLETED
                 else
                   Statuses::COMPLETED_WITH_ERRORS
                 end
    self.status = new_status
    save!
  end

  private

  # @return [Array<String>]
  def all_unique_batch_file_statuses
    batch_files.distinct.pluck(:status)
  end
end
