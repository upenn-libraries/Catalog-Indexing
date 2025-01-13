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
  validates :full, inclusion: [true, false]
  validates :job_identifier, presence: true

  scope :filter_status, ->(status) { where(status: status) }
  scope :filter_full, ->(full) { where(full: full == 'true') }
  scope :filter_sort_by, ->(value, order) { order(value => order) }

  # @param job_id [String]
  # @param alma_source [String (frozen)]
  # @return [AlmaExport]
  def self.create_full!(job_id:, alma_source: AlmaExport::Sources::PRODUCTION)
    AlmaExport.create! status: Statuses::PENDING, alma_source: alma_source,
                       job_identifier: job_id, full: true
  end

  # @param job_id [String]
  # @param alma_source [String (frozen)]
  # @return [AlmaExport]
  def self.create_incremental!(job_id:, alma_source: AlmaExport::Sources::PRODUCTION)
    AlmaExport.create! status: Statuses::PENDING, alma_source: alma_source,
                       job_identifier: job_id, full: false
  end

  # @param inline [Boolean]
  def process!(inline: false)
    raise unless status == Statuses::PENDING

    if full? && inline
      ProcessFullAlmaExport.new.call alma_export_id: id
    elsif full
      ProcessFullAlmaExportJob.perform_async id
    elsif inline
      ProcessIncrementalAlmaExport.new.call alma_export_id: id
    else
      ProcessIncrementalAlmaExportJob.perform_async id
    end
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
