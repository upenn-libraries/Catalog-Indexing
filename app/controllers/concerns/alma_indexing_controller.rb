# frozen_string_literal: true

class AlmaIndexingController < ApplicationController
  def index; end

  def process_ids
    ids = params[:mms_ids].split(", ")
    ids.length <= AlmaApi::Client::MAX_BIBS_GET ? puts("success: #{ids.inspect}") : puts('failure!')
    if ids.length <= AlmaApi::Client::MAX_BIBS_GET
      # send IDs to alma
      redirect_to root_path, notice: 'Success!'
    else
      redirect_to root_path, alert: "Number of MMS IDs exceeds the limit (#{AlmaApi::Client::MAX_BIBS_GET})"
    end
  end
end

