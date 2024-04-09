# frozen_string_literal: true

require 'dry/transaction'

# with an Array of MMSIDs as a parameter, get MARCXML from the Alma API and index via Traject
class IndexByIdentifier
  include Dry::Transaction(container: Container)

  step :retrieve_marcxml, with: 'marcxml.retrieve' # get MARCXML from Alma API
  step :prepare_marcxml, with: 'marcxml.prepare' # massage MARCXML
  step :prepare_writer
  step :index_via_traject, with: 'traject.index_records' # receive a IO object and do the indexing

  # Prepare Traject indexer, with a setting to perform a commit upon closing the writer (job completion).
  # This will make any added records immediately searchable.
  # @returns [Dry::Monads::Result]
  def prepare_writer(**args)
    # TODO: what collection to use here? use an arg (from a form element?) or a ConfigItem? or a production alias?
    settings = { 'solr_writer.commit_on_close' => true,
                 # 'solr_writer.target_collections' => args[:target_collection]
               }
    writer = MultiCollectionWriter.new(settings)
    Success(writer: writer, **args)
  end
end
