# frozen_string_literal: true

# Listens for and handles Alma Webhooks
class WebhookIndexingController < ApplicationController
  before_action :validate, only: [:listen]

  # echo challenge phrase back to Alma
  def challenge
    render json: challenge_params
  end

  # listens for and routes webhook events to appropriate handler
  def listen
    payload = JSON.parse(request.body.string)
    action = payload['action']
    case action
    when 'BIB'
      bib(payload)
    when 'JOB_UPDATED'
      # do something
    else
      head(:bad_request)
    end
  end

  private

  def bib(payload)
    # marc_xml = payload.dig 'bib', 'anies'
    # TODO: respect "suppress_from_publishing"?
    case payload.dig 'event', 'value'
    when 'BIB_UPDATED'
      # run bib updated job
      head :ok
    when 'BIB_DELETED'
      # run bib deleted job
      head :ok
    when 'BIB_CREATED'
      # run bib created job
      head :ok
    else
      head :bad_request
    end
  end

  # validate the signature header based on webhook secret and the request body content to ensure request came from Alma
  def valid_signature?
    hmac = OpenSSL::HMAC.new ENV.fetch('ALMA_WEBHOOK'), OpenSSL::Digest.new('sha256')
    hmac.update request.body.string
    signature =  request.get_header('X-Exl-Signature') || request.get_header('HTTP_X_EXL_SIGNATURE')
    signature == Base64.strict_encode64(hmac.digest)
  end

  def validate
    valid_signature? || head(:unauthorized)
  end

  def challenge_params
    params.permit(:challenge)
  end
end
