# frozen_string_literal: true

module Webhook
  # Represent an Alma Job webhook
  class Job < Payload
    def id; end

    def event; end

    def job_name; end

    def job_status; end

    def job_counter_updated_records; end

    def job_counter_deleted_records; end
  end
end
