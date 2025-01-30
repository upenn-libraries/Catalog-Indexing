# frozen_string_literal: true

# Helper methods for extracting and parsing information from the Alma Export webhook body
module JobDetails
  # Start time from webhook body
  # @return [Time, nil]
  def job_started_at
    parse_job_timestamp('start_time')
  end

  # End time from webhook body
  # @return [Time, nil]
  def job_ended_at
    parse_job_timestamp('end_time')
  end

  # Duration between job start and end
  # @return [String]
  def job_duration
    return unless job_started_at && job_ended_at

    Time.at(job_ended_at - job_started_at).utc.strftime('%H:%M:%S')
  end

  # Amount of new records in the job
  # @return [String, nil]
  def new_records
    counter_value('label.new.records')
  end

  # Amount of updated records in the job
  # @return [String, nil]
  def updated_records
    counter_value('label.updated.records')
  end

  # Amount of deleted records in the job
  # @return [String, nil]
  def deleted_records
    counter_value('label.deleted.records')
  end

  private

  # Parse the related `value` from the specified key from the `counter` from the webhook body
  # @return [String, nil]
  def counter_value(value_key)
    counter = webhook_body&.dig('job_instance', 'counter')
    return unless counter

    counter.find { |item| item&.dig('type', 'value') == value_key }&.fetch('value')
  end

  # Parse a timestamp from the webhook body
  # @param key [String]
  # @return [Time, nil]
  def parse_job_timestamp(key)
    timestamp = webhook_body&.dig('job_instance', key)
    return unless timestamp

    Time.zone.parse(timestamp)
  end
end
