# frozen_string_literal: true

require 'dry/transaction'

# with an MMS ID as a parameter, remove the record from the Solr index
class DeleteByIdentifier
  include Dry::Transaction(container: Container)

  step :get_collections
  step :build_params
  step :issue_deletes

  def get_collections(**args)
    collections = Array.wrap(args[:collections] || ConfigItem.value_for(:webhook_target_collections))
    Success(collections: collections, **args)
  end

  def build_params(**args)
    commit_within = args[:commit_within] || Settings.solr.webhook_action_commit_within_time
    params = { 'commitWithin' => commit_within }
    Success(params: params, **args)
  end

  # @param [String] id
  def issue_deletes(id:, collections:, params:, **_args)
    collections.map do |collection|
      solr = Solr::QueryClient.new(collection: collection)
      solr.delete id: id, args: { params: params }
    end
    Success("Record #{id} removed from Solr") # TODO: wat if response is not successful?
  rescue RSolr::Error => e
    Failure(e.message)
  rescue StandardError => e
    Failure(e.message)
  end
end
