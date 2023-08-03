# frozen_string_literal: true

class AlmaIndexingController < ApplicationController
  def index; end

  def process_ids
    ids = params[:mms_ids].squish.split(/,\s*|,/)
    if ids.length <= AlmaApi::Client::MAX_BIBS_GET
      IndexByIdentifiers.perform_inline ids # TODO: see how well inline runs...
      # send IDs to alma
      redirect_to root_path, notice: 'Success!'
    else
      redirect_to root_path, alert: "Number of MMS IDs (#{ids.length}) exceeds the limit (#{AlmaApi::Client::MAX_BIBS_GET})"
    end
  end
end

