# frozen_string_literal: true

# Represent a completed Export from Alma. Alma Exports have a 1:1 relation to the running of an Alma Publishing job.
# This entity contains information about the job and information about the target Solr collections for the indexing of
# the exported records.
class AlmaExport < ApplicationRecord
  include Statuses

  class InvalidStatusError < StandardError; end

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

  # Create and AlmaExport representing an Alma full publish
  # @param job_id [String]
  # @param alma_source [String]
  # @return [AlmaExport]
  def self.create_full!(job_id:, alma_source: Sources::PRODUCTION)
    AlmaExport.create! status: PENDING, alma_source: alma_source, job_identifier: job_id, full: true
  end

  # Create an AlmaExport representing an Alma incremental publish
  # @param job_id [String]
  # @param alma_source [String]
  # @return [AlmaExport]
  def self.create_incremental!(job_id:, alma_source: Sources::PRODUCTION)
    AlmaExport.create! status: PENDING, alma_source: alma_source, job_identifier: job_id, full: false
  end

  # "Process" the AlmaExport by passing it to the Job or Transaction
  # @param inline [Boolean] inline processing will occur if this is true
  # @return [TrueClass, Dry::Monads::Result, nil]
  def process!(inline: false)
    unless status == PENDING
      raise InvalidStatusError, "AlmaExport ##{id} is in #{status} state. Only records in #{PENDING} can be processed."
    end

    return process_inline if inline

    enqueue_processing_job
  end

  # Count of BatchFiles for this AlmaExport matching status
  # @param status [String]
  # @return [Integer]
  def status_count(status)
    batch_files.filter_status(status).count
  end

  # query to see if all associated BatchFiles are in a completed state (completed, completed with errors, failed)
  # @param statuses [Array<String>]
  # @return [Boolean]
  def all_batch_files_finished?(statuses = unique_batch_file_statuses)
    statuses.none? { |status| status.in? INCOMPLETE_STATUSES }
  end

  # set to appropriate completed status and save
  # @return [nil]
  def set_completion_status!
    new_status = derive_completion_status
    return unless new_status

    update!({
              completed_at: Time.current,
              status: new_status
            })
  end

  # Start time from webhook body
  # @return [Time]
  def job_started_at
    parse_job_timestamp('start_time')
  end

  # End time from webhook body
  # @return [Time]
  def job_ended_at
    parse_job_timestamp('end_time')
  end

  # Duration between job start and end
  # @return [String]
  def job_duration
    return unless job_started_at && job_ended_at

    Time.at(job_ended_at - job_started_at).utc.strftime('%H:%M:%S')
  end

  private

  # Parse a timestamp from the webhook body
  # @param key [String]
  # @return [nil, Time]
  def parse_job_timestamp(key)
    timestamp = webhook_body&.dig('job_instance', key)
    return unless timestamp

    Time.zone.parse(timestamp)
  end

  # @param statuses [Array<String>]
  # @return [nil, String]
  def derive_completion_status(statuses = unique_batch_file_statuses)
    return unless all_batch_files_finished?(statuses)

    if statuses == [FAILED]
      FAILED
    elsif statuses == [COMPLETED]
      COMPLETED
    else
      COMPLETED_WITH_ERRORS
    end
  end

  # @return [Array<String>]
  def unique_batch_file_statuses
    ActiveRecord::Base.uncached do
      batch_files.reload.distinct.pluck(:status)
    end
  end

  # @return [Dry::Monads::Result]
  def process_inline
    transaction = full? ? ProcessFullAlmaExport : ProcessIncrementalAlmaExport
    transaction.new.call(alma_export_id: id)
  end

  # @return [TrueClass, nil]
  def enqueue_processing_job
    job = full? ? ProcessFullAlmaExportJob : ProcessIncrementalAlmaExportJob
    job.perform_async(id)
  end
end
