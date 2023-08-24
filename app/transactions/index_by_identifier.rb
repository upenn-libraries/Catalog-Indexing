# frozen_string_literal: true

require 'dry/transaction'

# with an Array of MMSIDs as a parameter, get MARCXML from the Alma API and index via Traject
class IndexByIdentifier
  include Dry::Transaction(container: Container)

  step :retrieve_marcxml # call Alma API with MMSIDs and return Array of MARCXML
  step :prepare_marcxml # massage MARCXML - for now ensure UTF-8
  step :index_via_traject, with: 'traject.index_records' # receive a IO object and do the indexing

  private

  # Get MARCXML from Alma API, strip XML doctype declaration
  # @param [Array<String>] identifiers
  # @return [Dry::Monads::Result]
  def retrieve_marcxml(identifiers:)
    response = AlmaApi::Client.new.bibs identifiers
    docs = response['bib']&.filter_map do |bib_data|
      bib_data['anies'].first
    end
    Success docs: docs
  rescue StandardError => e
    Failure e
  end

  # Shove MARCXML into a XML string for a MARCXMLReader to parse into MARC::Record objects
  # @param [Hash] args
  # @return [Dry::Monads::Result]
  def prepare_marcxml(args)
    xml = args[:docs].join.gsub('<?xml version="1.0" encoding="UTF-16"?>', '')
    io = StringIO.new "<?xml version=\"1.0\" encoding=\"UTF-8\"?><collection>#{xml}</collection>"

    Success(io: io)
  rescue StandardError => e
    Failure e
  end
end