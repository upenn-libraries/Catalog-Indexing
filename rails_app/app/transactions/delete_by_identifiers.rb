# frozen_string_literal: true

require 'dry/transaction'

# with an MMS ID as a parameter, remove the record from the Solr index
class DeleteByIdentifiers
  include Dry::Transaction(container: Container)

  step :get_collections, with: 'config_item.adhoc_target_collections'
  step :build_params
  step :issue_deletes

  # Assemble additional params for Solr request
  # @option commit_within [Integer]
  # @return [Dry::Monads::Result]
  def build_params(**args)
    commit_within = args[:commit_within] || Settings.solr.webhook_action_commit_within_time_ms
    commit = args[:commit] == true
    params = { 'commitWithin' => commit_within, 'commit' => commit }
    Success(params: params, **args)
  end

  # Send delete to Solr for each specified collection, with params added to the Solr URL
  # @param mms_ids [String, Array]
  # @param collections [Array]
  # @param params [Hash]
  # @return [Dry::Monads::Result]
  def issue_deletes(mms_ids:, collections:, params:, **_args)
    mms_ids = Array.wrap(mms_ids)
    collections.map do |collection|
      solr = Solr::QueryClient.new(collection: collection)
      solr.delete ids: mms_ids, args: { params: params }
    end
    Success("Record(s) #{mms_ids.join(', ')} removed from Solr")
  rescue StandardError => e
    Failure(exception: e)
  end
end
