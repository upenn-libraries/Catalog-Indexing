# frozen_string_literal: true

require 'dry/transaction'

# with an Alma set ID as a parameter, get set members, then MARCXML from the Alma API and index via Traject
class IndexBySetToFile
  include Dry::Transaction(container: Container)

  step :get_set_members
  step :retrieve_marcxml
  step :prepare_marcxml, with: 'prepare_marcxml' # massage MARCXML - for now ensure UTF-8
  step :prepare_file_writer
  step :index_via_traject, with: 'traject.index_records' # receive a IO object and do the indexing
  step :deliver_file

  private

  def get_set_members(set_id:, **args)
    set_response = AlmaApi::Client.new.set_members(set_id)
    mms_ids = set_response.pluck 'id'
    Success(identifiers: mms_ids, **args)
  end

  # Get MARCXML from Alma API
  # @todo Step-ify if possible
  # @param [Array<String>] identifiers
  # @return [Dry::Monads::Result]
  def retrieve_marcxml(identifiers:, **args)
    docs = []
    identifiers.in_groups_of(AlmaApi::Client::MAX_BIBS_GET, false).each do |group|
      response = AlmaApi::Client.new.bibs group
      docs += response['bib']&.filter_map do |bib_data|
        bib_data['anies'].first
      end
    end
    Success(docs: docs, **args)
  rescue StandardError => e
    Failure(e)
  end

  ## prepare_marcxml

  def prepare_file_writer(io:, **args)
    # TODO: determine writer based on something in args? There may be a use case... Like if we added a "set" option
    #       to the Index by Identifier UI, we'd want to support the MultiCollectionWriter...
    filename = Rails.root.join('storage/sample_set_solr.jsonl')
    writer = Traject::JsonWriter.new({'output_file' => filename })
    Success(io: io, writer: writer, filename: filename, **args)
  rescue StandardError => e
    Failure("Problem preparing writer: #{e.message}")
  end

  ## index_via_traject

  # Pass in a flag that, if set, uploads file to canonical location on FTP for access by task in catalog app?
  def deliver_file(filename:, push_to_ftp: false, **_args)
    Success("Solr JSON file is in place @ #{filename}")
    # TODO: push generated SolrJSON file to some canonical FTP location
    #       like: Sftp::Client.new.put("catalog_solrjson/#{filename}")
  end
end
