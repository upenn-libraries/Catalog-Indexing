# frozen_string_literal: true

require 'dry/transaction'

# with an MMS ID as a parameter, remove the record from the Solr index
class DeleteByIdentifier
  include Dry::Transaction(container: Container)

  # @param [String] id
  def issue_delete(id:, **_args)
    commit_within = args[:commit_within] || Settings.solr.webhook_action_commit_within_time
    outcome = RSolr.delete_by_id id, { params: { 'commitWithin' => commit_within } }
    Success("Record #{id} removed from Solr") # TODO: wat if response is not successful?
  rescue RSolr::Error => e
    # TODO: try again?
  rescue StandardError => e
    # TODO: give up
  end
end
