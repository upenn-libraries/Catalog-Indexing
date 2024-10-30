# frozen_string_literal: true

# actions surrounding ad hoc record indexing
class AlmaIndexingController < ApplicationController
  before_action :validate_mmsids, only: %i[add delete]

  def index; end

  def add
    outcome = IndexByIdentifiers.new.call identifiers: mms_ids, commit: true
    if outcome.success? && outcome.success[:errors].empty?
      redirect_to adhoc_indexing_path, notice: "Sent updates to Solr for #{mms_ids.to_sentence}."
    else
      redirect_to adhoc_indexing_path, notice: error_message_from(outcome)
    end
  end

  def delete
    outcome = DeleteByIdentifiers.new.call mms_ids: mms_ids, commit: true
    if outcome.success?
      redirect_to adhoc_indexing_path, notice: outcome.success
    else
      redirect_to adhoc_indexing_path, notice: outcome.failure[:message] || outcome.failure[:exception]&.message
    end
  end

  private

  def mms_ids
    params[:mms_ids].squish.split(/,\s*|,/)
  end

  # @return [Boolean]
  def validate_mmsids
    alert = if mms_ids.length > AlmaApi::Client::MAX_BIBS_GET
              "Number of MMS IDs (#{mms_ids.length}) exceeds the limit (#{AlmaApi::Client::MAX_BIBS_GET})"
            elsif mms_ids.empty?
              'No MMS IDs provided'
            end
    if alert
      redirect_to(adhoc_indexing_path, alert: alert)
      false
    end
    true
  end

  # @param outcome [Dry::Monads::Result]
  def error_message_from(outcome)
    if outcome.success? && outcome.success[:errors].any?
      "Problems indexing some records: #{outcome.success[:errors].join(',')}."
    else
      "Bad news: #{outcome.failure}"
    end
  end
end
