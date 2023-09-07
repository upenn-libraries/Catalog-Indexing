# frozen_string_literal: true

# Index to Solr with MMS IDs, via Alma API and Traject
class ProcessAlmaExportJob
  include Sidekiq::Job

  # @param [String] webhook_body
  def perform(webhook_body)
    outcome = ProcessAlmaExport.new.call(webhook_body: webhook_body)
    outcome.success?
    # Notify based on failure outcomes?
  end
end
