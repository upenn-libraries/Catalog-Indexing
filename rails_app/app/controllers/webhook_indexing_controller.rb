# frozen_string_literal: true

# Listens for and handles Alma Webhooks
class WebhookIndexingController < ApplicationController
  skip_before_action :authenticate_user!, :verify_authenticity_token
  before_action :validate, only: [:listen]

  # echo challenge phrase back to Alma
  def challenge
    render json: challenge_params
  end

  # listens for and handles webhook events
  def listen
    payload = JSON.parse(request.body.string)
    handle_action_type(payload)
  rescue JSON::ParserError => _e
    head(:bad_request)
  rescue ActiveRecord::RecordInvalid => _e
    # TODO: Notify of error
    head(:internal_server_error)
  end

  private

  # @param payload [Hash]
  def handle_action_type(payload)
    webhook = Webhook::Payload.build payload: payload
    case webhook
    when Webhook::Bib
      if ConfigItem.value_for(:process_bib_webhooks)
        handle_bib_action(webhook)
      else
        head(:ok)
      end
    when Webhook::Job
      if ConfigItem.value_for(:process_job_webhooks) && webhook.successful_publishing_job?
        initialize_alma_export(webhook)
      else
        Rails.logger.info { 'Completed job is not interesting. No job enqueued.' }
        head(:ok)
      end
    else
      head(:no_content)
    end
  end

  # Handles alma webhook bib actions
  # @param [Webhook::Bib] webhook data
  # @return [TrueClass]
  # rubocop:disable Metrics/AbcSize
  def handle_bib_action(webhook)
    return head(:ok) if webhook.suppress_from_discovery?

    case webhook.event
    when 'BIB_UPDATED'
      IndexByBibEventJob.perform_async(webhook.marcxml)
      Rails.logger.info "Webhook: BIB_UPDATED job enqueued for #{webhook.id}"
      head :accepted
    when 'BIB_DELETED'
      # TODO: should we delete regardless of the suppression values?
      DeleteByIdentifiersJob.perform_async(webhook.id)
      Rails.logger.info "Webhook: BIB_DELETED job enqueued for #{webhook.id}"
      head :accepted
    when 'BIB_CREATED'
      IndexByBibEventJob.perform_async(webhook.marcxml)
      Rails.logger.info "Webhook: BIB_CREATED job enqueued for #{webhook.id}"
      head :accepted
    else
      head :no_content
    end
  end
  # rubocop:enable Metrics/AbcSize

  # @param [Webhook::Job] webhook
  # @return [TrueClass]
  def initialize_alma_export(webhook)
    alma_export = AlmaExport.create!(status: Statuses::PENDING, alma_source: AlmaExport::Sources::PRODUCTION,
                                     webhook_body: webhook.data, full: webhook.full_publish?)
    job = webhook.full_publish? ? ProcessFullAlmaExportJob : ProcessIncrementalAlmaExportJob
    Rails.logger.info { "Completed job is interesting! Enqueueing #{job}." }
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
end
