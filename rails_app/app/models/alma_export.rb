# frozen_string_literal: true

# Represent a completed Export from Alma. Alma Exports have a 1:1 relation to the running of an Alma Publishing job.
# This entity contains information about the job and information about the target Solr collections for the indexing of
# the exported records.
class AlmaExport < ApplicationRecord
  include Statuses

  JOB_SUCCESS_VALUE = 'COMPLETED_SUCCESS'

  module Sources
    PRODUCTION = 'production'
    SANDBOX = 'sandbox'
    ALL = [PRODUCTION, SANDBOX].freeze
  end

  has_many :batch_files, dependent: :destroy

  validates :alma_source, inclusion: Sources::ALL, presence: true
  validates :full, inclusion: [true, false]
  validates :webhook_body, presence: true

  scope :filter_status, ->(status) { where(status: status) }
  scope :filter_full, ->(full) { where(full: full == 'true') }
  scope :filter_sort_by, ->(value, order) { order(value => order) }

  # @return [String, nil]
  def alma_job_identifier
    webhook_body.dig('job_instance', 'id')
  end

  # Count of BatchFiles for this AlmaExport matching status
  # @param status [String]
  # @return [Integer]
  def status_count(status)
    batch_files.filter_status(status).count
  end

  # query to see if all associated BatchFiles are in a completed state (completed, completed with errors, failed)
  # @param [Array<String>] statuses
  # @return [Boolean]
  def all_batch_files_finished?(statuses = unique_batch_file_statuses)
    statuses.none? { |status| status.in? Statuses::INCOMPLETE_STATUSES }
  end

  # set to appropriate completed status and save
  # @return [NilClass]
  def set_completion_status!
    new_status = derive_completion_status
    return unless new_status

    update!({
              completed_at: Time.current,
              status: new_status
            })
  end

  private

  # @param [Array<String>] statuses
  # @return [NilClass | String (frozen)]
  def derive_completion_status(statuses = unique_batch_file_statuses)
    return unless all_batch_files_finished?(statuses)

    if statuses == [Statuses::FAILED]
      Statuses::FAILED
    elsif statuses == [Statuses::COMPLETED]
      Statuses::COMPLETED
    else
      Statuses::COMPLETED_WITH_ERRORS
    end
  end

  # @return [Array<String>]
  def unique_batch_file_statuses
    ActiveRecord::Base.uncached do
      batch_files.reload.distinct.pluck(:status)
    end
  end
end
