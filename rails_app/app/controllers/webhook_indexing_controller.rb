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

  # @param [Hash] payload
  # @return [TrueClass]
  def handle_action_type(payload)
    case payload['action']
    when 'BIB'
      return unless ConfigItem.value_for(:process_bib_webhooks)

      handle_bib_action(payload)
    when 'JOB_END'
      handle_job_action(payload)
    else
      head(:bad_request)
    end
  end

  # Handles alma webhook bib actions
  # @param [Hash] payload action-specific data received from alma webhook post request
  # @return [TrueClass]
  def handle_bib_action(payload)
    marc_xml = payload.dig 'bib', 'anies'
    # TODO: respect "suppress_from_publishing"?
    case payload.dig 'event', 'value'
    when 'BIB_UPDATED'
      IndexByBibEventJob.perform_async(marc_xml)
      head :ok
    when 'BIB_DELETED'
      # run bib deleted job
      head :ok
    when 'BIB_CREATED'
      IndexByBibEventJob.perform_async(marc_xml)
      head :ok
    else
      head :bad_request
    end
  end

  # @param [Hash] payload
  # @return [TrueClass]
  def handle_job_action(payload)
    alma_export = AlmaExport.create!(status: Statuses::PENDING, alma_source: AlmaExport::Sources::PRODUCTION,
                                     webhook_body: payload,
                                     target_collections: Array.wrap(Solr::Config.new.collection_name))
    ProcessAlmaExportJob.perform_async(alma_export.id)
    head :ok
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
end
