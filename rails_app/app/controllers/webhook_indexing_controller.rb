# frozen_string_literal: true

# Listens for and handles Alma Webhooks
class WebhookIndexingController < ApplicationController
  skip_before_action :authenticate_user!
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
    head(:unprocessable_entity)
  rescue ActiveRecord::RecordInvalid => _e
    # TODO: Notify of error
    head(:internal_server_error)
  end

  private

  # @param payload [Hash]
  def handle_action_type(payload)
    case payload['action']
    when 'BIB'
      if ConfigItem.value_for(:process_bib_webhooks)
        handle_bib_action(payload)
      else
        head(:ok)
      end
    when 'JOB_END'
      if ConfigItem.value_for(:process_job_webhooks) && completed_publishing_job?(payload)
        initialize_alma_export(payload)
      else
        head(:ok)
      end
    else
      head(:no_content)
    end
  end

  # Handles alma webhook bib actions
  # @param [Hash] payload action-specific data received from alma webhook post request
  # @return [TrueClass]
  def handle_bib_action(payload)
    head(:ok) if suppressed_from_discovery?(payload)

    marc_xml = payload.dig 'bib', 'anies'
    case payload.dig 'event', 'value'
    when 'BIB_UPDATED'
      IndexByBibEventJob.perform_async(marc_xml)
      head :accepted
    when 'BIB_DELETED'
      # TODO: write and run bib deleted job, return :accepted
      head :not_implemented
    when 'BIB_CREATED'
      IndexByBibEventJob.perform_async(marc_xml)
      head :accepted
    else
      head :no_content
    end
  end

  # @param payload [Hash]
  # @return [TrueClass]
  def initialize_alma_export(payload)
    alma_export = AlmaExport.create!(status: Statuses::PENDING, alma_source: AlmaExport::Sources::PRODUCTION,
                                     webhook_body: payload)
    ProcessAlmaExportJob.perform_async(alma_export.id)

    head :accepted
  end

  # Ensure the webhook is telling us about a successfully completed Publishing job of the correct type
  # @param payload [Hash]
  def completed_publishing_job?(payload)
    job_name = payload.dig('job_instance', 'name')
    job_status = payload.dig('job_instance', 'status', 'value')
    (job_name == Settings.alma.publishing_job.name) && (job_status == AlmaExport::JOB_SUCCESS_VALUE)
  end

  # Determines if the alma webhook signature header is valid to ensure request came from Alma
  # @return [Boolean]
  def valid_signature?
    hmac = OpenSSL::HMAC.new ENV.fetch('ALMA_WEBHOOK'), OpenSSL::Digest.new('sha256')
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

  # @param [Hash] payload
  # @return [Boolean]
  def suppressed_from_discovery?(payload)
    (payload.dig(:bib, :suppress_from_publishing) == true) ||
      (payload.dig(:bib, :suppress_from_external_search) == true)
  end
end
