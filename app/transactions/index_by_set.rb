# frozen_string_literal: true

require 'dry/transaction'

# with an Array of MMSIDs as a parameter, get MARCXML from the Alma API and index via Traject
class IndexByIdentifier
  include Dry::Transaction(container: Container)

  step :get_set_members
  step :retrieve_marcxml
  step :prepare_marcxml, with: 'prepare_marcxml' # massage MARCXML - for now ensure UTF-8
  step :index_via_traject, with: 'traject.index_records' # receive a IO object and do the indexing
  step :deliver_file

  private

  def get_set_members(set_id:, **args)
    set_response = AlmaApi::Client.new.set_members(set_id)
    set_response.collect { |member| member['id'] }
    Success(identifiers: mms_ids, **args)
  end

  # Get MARCXML from Alma API
  # @todo Step-ify if possible
  # @param [Array<String>] identifiers
  # @return [Dry::Monads::Result]
  def retrieve_marcxml(identifiers:, **args)
    docs = []
    identifiers.in_groups_of(AlmaApi::Client::MAX_BIBS_GET, fill_with: false).each do |group|
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

  ## index_via_traject TODO: need to pass in writer, along to IndexingService

  # Pass in a flag that, if set, uploads file to canonical location on FTP for access by task in catalog app?
  def deliver_file(filename:, push_to_ftp: false, **_args)
    return Success("Solr JSON file is in place @ #{filename}") unless push_to_ftp

    # TODO: push generated SolrJSON file to some canonical FTP location
  end
end
