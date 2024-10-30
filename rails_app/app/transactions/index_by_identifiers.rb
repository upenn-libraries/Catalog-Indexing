# frozen_string_literal: true

require 'dry/transaction'

# with an Array of MMSIDs as a parameter, get MARCXML from the Alma API and index via Traject
class IndexByIdentifiers
  include Dry::Transaction(container: Container)

  step :retrieve_marcxml, with: 'marcxml.retrieve' # get MARCXML from Alma API
  step :prepare_marcxml, with: 'marcxml.prepare' # massage MARCXML
  step :prepare_writer
  step :index_via_traject, with: 'traject.index_records' # receive a IO object and do the indexing

  # Prepare Traject indexer, with a setting to perform a commit upon closing the writer (job completion).
  # This will make any added records immediately searchable.
  # @return [Dry::Monads::Result]
  def prepare_writer(**args)
    collections = ConfigItem.value_for :adhoc_target_collections
    writer = MultiCollectionWriter.new(collections: collections, commit_on_close: true)
    Success(writer: writer, **args)
  end
end
