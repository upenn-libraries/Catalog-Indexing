# frozen_string_literal: true

# actions surrounding ad hoc record indexing
class AlmaIndexingController < ApplicationController
  before_action :validate_mmsids, only: :process_ids

  def index; end

  def process_ids
    if mms_ids.length <= inline_threshold
      call_transaction
    else
      IndexByIdentifiers.perform_async mms_ids
      redirect_to root_path, notice: 'This many records will have to be indexed in a background job.'
    end
  end

  private

  def call_transaction
    IndexByIdentifier.new.call(identifiers: mms_ids) do |result|
      result.success do |_success|
        redirect_to root_path, notice: 'Records indexed successfully'
      end
      result.failure do |exception|
        redirect_to root_path, notice: "Indexing job failed: #{exception.message}"
      end
    end
  end

  def mms_ids
    params[:mms_ids].squish.split(/,\s*|,/)
  end

  def inline_threshold
    AlmaApi::Client::MAX_BIBS_GET / 2
  end

  # @return [Boolean]
  def validate_mmsids
    if mms_ids.length > AlmaApi::Client::MAX_BIBS_GET
      redirect_to root_path,
                  alert: "Number of MMS IDs (#{mms_ids.length}) exceeds the limit (#{AlmaApi::Client::MAX_BIBS_GET})"
      false
    end
    true
  end
end

