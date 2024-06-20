# frozen_string_literal: true

require 'dry/transaction'

# with an MMS ID as a parameter, remove the record from the Solr index
class DeleteByIdentifier
  include Dry::Transaction(container: Container)

  step :get_collections
  step :build_params
  step :issue_deletes

  # Get the collections names from which the record should be deleted, either from args or from the ConfigItem
  # @option collections [Array]
  # @return [Dry::Monads::Result]
  def get_collections(**args)
    collections = Array.wrap(args[:collections] || ConfigItem.value_for(:webhook_target_collections))
    Success(collections: collections, **args)
  end

  # Assemble additional params for Solr request
  # @return [Dry::Monads::Result]
  def build_params(**args)
    commit_within = args[:commit_within] || Settings.solr.webhook_action_commit_within_time_ms
    params = { 'commitWithin' => commit_within }
    Success(params: params, **args)
  end

  # Send delete to Solr for each specified collection, with
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
    Failure(e.message)
  end
end
