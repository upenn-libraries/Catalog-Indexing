# frozen_string_literal: true

# Index to Solr with MMS IDs, via Alma API and Traject
class PublishJobProcessJob
  include Sidekiq::Job

  # @param [String] webhook_body
  def perform(webhook_body)
    outcome = ProcessPublishJob.call(webhook_body: webhook_body)
    outcome.success?
    # Notify based on failure outcomes?
  end
end
