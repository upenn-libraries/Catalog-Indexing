# frozen_string_literal: true

class AlmaIndexingController < ApplicationController
  def index; end

  def process_ids
    ids = params[:mms_ids].split(", ")
    ids.length <= AlmaApi::Client::MAX_BIBS_GET ? puts("success: #{ids.inspect}") : puts('failure!')
    if ids.length <= AlmaApi::Client::MAX_BIBS_GET
      # send IDs to alma
      flash.notice = "Success!"
    else
      flash.alert = "Number of MMS IDs exceeds the limit (#{AlmaApi::Client::MAX_BIBS_GET})"
    end
    redirect_to root_path
  end
end

