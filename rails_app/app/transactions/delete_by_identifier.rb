# frozen_string_literal: true

require 'dry/transaction'

# with an MMS ID as a parameter, remove the record from the Solr index
class DeleteByIdentifier
  include Dry::Transaction(container: Container)

  step :get_collections, with: 'webhooks.get_collections'
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
  # @param id [String]
  # @param collections [Array]
  # @param params [Hash]
  # @return [Dry::Monads::Result]
  def issue_deletes(id:, collections:, params:, **_args)
    collections.map do |collection|
      solr = Solr::QueryClient.new(collection: collection)
      solr.delete id: id, args: { params: params }
    end
    Success("Record #{id} removed from Solr")
  rescue StandardError => e
    Failure(exception: e)
  end
end
