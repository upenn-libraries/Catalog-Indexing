# frozen_string_literal: true

module Webhook
  # Represent an Alma Job webhook
  class Job < Payload
    def id
      data['id']
    end

    # @return [String]
    def job_name
      data.dig 'job_instance', 'name'
    end

    # @return [String]
    def job_status
      data.dig 'job_instance', 'status', 'value'
    end

    # @return [String]
    def job_counter_updated_records
      data.dig('job_instance', 'counter').find { |val| val.dig('type', 'value') == 'label.updated.records' }['value']
    end

    # @return [String]
    def job_counter_deleted_records
      data.dig('job_instance', 'counter').find { |val| val.dig('type', 'value') == 'label.deleted.records' }['value']
    end
    
    # @return [Boolean]
    def full_publish?
      (job_counter_deleted_records == '0') && (job_counter_updated_records == '0')
    end

    # @return [Boolean]
    def successful_publishing_job?
      (job_name == Settings.alma.publishing_job.name) &&
        job_status.in?(AlmaExport::JOB_SUCCESS_VALUES)
    end
  end
end
