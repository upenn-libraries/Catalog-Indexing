# frozen_string_literal: true

# actions surrounding ad hoc record indexing
class AlmaIndexingController < ApplicationController
  before_action :validate_mmsids, only: :process_ids

  def index; end

  def process_ids
    IndexByIdentifiersJob.perform_async mms_ids
    redirect_to root_path, notice: 'Indexing job enqueued.'
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
      redirect_to(index_by_id_path, alert: alert)
      false
    end
    true
  end
end
