# frozen_string_literal: true

# actions surrounding ad hoc record indexing
class AlmaIndexingController < ApplicationController
  before_action :validate_configuration
  before_action :validate_mmsids, only: %i[add delete]

  def index; end

  def add
    outcome = IndexByIdentifiers.new.call identifiers: mms_ids
    if outcome.success? && outcome.success[:errors].empty?
      redirect_to adhoc_indexing_path, notice: t('ad_hoc.add.success', ids: mms_ids.to_sentence)
    else
      redirect_to adhoc_indexing_path, alert: error_message_for(outcome)
    end
  end

  def delete
    # run the transaction inline with a commit param that ensures the changes are effective immediately
    outcome = DeleteByIdentifiers.new.call mms_ids: mms_ids, commit: true
    if outcome.success?
      redirect_to adhoc_indexing_path, notice: outcome.success
    else
      redirect_to adhoc_indexing_path, alert: outcome.failure[:message] || outcome.failure[:exception]&.message
    end
  end

  private

  def mms_ids
    params[:mms_ids].squish.split(/,\s*|,/)
  end

  # @return [Boolean]
  def validate_mmsids
    alert = if mms_ids.length > AlmaApi::Client::MAX_BIBS_GET
              t('ad_hoc.validation.too_many_ids', length: mms_ids.length, limit: AlmaApi::Client::MAX_BIBS_GET)
            elsif mms_ids.empty?
              t('ad_hoc.validation.no_ids')
            end
    if alert
      redirect_to(adhoc_indexing_path, alert: alert)
      false
    end
    true
  end

  # Ensure that the expected ConfigItem is setup, otherwise indexing actions are bound to fail
  def validate_configuration
    return true if ConfigItem.any? && ConfigItem.value_for(:adhoc_target_collections).any?

    message = if ConfigItem.none?
                'You must run the rake:add_config_items task to initialize config items.'
              else
                'You must set a collection for the adhoc_target_collections configuration'
              end

    redirect_to config_items_path, alert: message
    false
  end

  # @param outcome [Dry::Monads::Result]
  # @return [String]
  def error_message_for(outcome)
    if outcome.success? && outcome.success[:errors].any?
      t('ad_hoc.add.mixed', messages: outcome.success[:errors].join(','))
    else
      t('ad_hoc.add.failure', message: outcome.failure)
    end
  end
end
