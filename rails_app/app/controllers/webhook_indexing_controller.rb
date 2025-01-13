# frozen_string_literal: true

# Listens for and handles Alma Webhooks
class WebhookIndexingController < ApplicationController
  skip_before_action :authenticate_user!, :verify_authenticity_token
  before_action :validate, only: [:listen]
  before_action :set_webhook, only: [:listen]

  # echo challenge phrase back to Alma
  def challenge
    render json: challenge_params
  end

  # listens for and handles webhook events
  def listen
    case @webhook
    when Webhook::Bib
      ConfigItem.value_for(:process_bib_webhooks) ? handle_bib_action : head(:ok)
    when Webhook::Job
      if ConfigItem.value_for(:process_job_webhooks) && @webhook.successful_publishing_job?
        initialize_alma_export
      else
        head(:ok)
      end
    else
      head(:no_content)
    end
  rescue ActiveRecord::RecordInvalid => e
    Honeybadger.notify e
    head(:internal_server_error)
  end

  private

  # Handles alma webhook bib actions
  # @return [TrueClass]
  def handle_bib_action
    return head(:ok) if @webhook.suppress_from_discovery?

    case @webhook.event
    when 'BIB_UPDATED'
      IndexByBibEventJob.perform_async(@webhook.marcxml)
      head :accepted
    when 'BIB_DELETED'
      # TODO: should we delete regardless of the suppression values?
      DeleteByIdentifiersJob.perform_async(@webhook.id)
      head :accepted
    when 'BIB_CREATED'
      IndexByBibEventJob.perform_async(@webhook.marcxml)
      head :accepted
    else
      head :no_content
    end
  end

  # @return [TrueClass]
  def initialize_alma_export
    alma_export = AlmaExport.create!(status: Statuses::PENDING, alma_source: AlmaExport::Sources::PRODUCTION,
                                     webhook_body: @webhook.data, job_identifier: @webhook.id, full: @webhook.full_publish?)
    job = @webhook.full_publish? ? ProcessFullAlmaExportJob : ProcessIncrementalAlmaExportJob
    job.perform_async(alma_export.id)
    head :accepted
  end

  # Determines if the alma webhook signature header is valid to ensure request came from Alma
  # @return [Boolean]
  def valid_signature?
    hmac = OpenSSL::HMAC.new Settings.alma.webhook_secret, OpenSSL::Digest.new('sha256')
    hmac.update request.body.string
    signature = request.get_header('X-Exl-Signature') || request.get_header('HTTP_X_EXL_SIGNATURE')
    encoded_digest = Base64.strict_encode64(hmac.digest)
    signature == encoded_digest
  end

  # Validates alma webhook post requests
  # @return [Boolean]
  def validate
    valid_signature? || head(:unauthorized)
  end

  def challenge_params
    params.permit(:challenge)
  end

  # Parse webhook body from response and build Webhook::Payload object
  def set_webhook
    payload = JSON.parse(request.body.string)
    @webhook = Webhook::Payload.build payload: payload
  rescue JSON::ParserError => e
    Honeybadger.notify e
    head(:bad_request)
  end
end
