# frozen_string_literal: true

require 'dry/transaction'

# with an Array of MMSIDs as a parameter, get MARCXML from the Alma API and index via Traject
class IndexByIdentifier
  include Dry::Transaction(container: Container)

  step :retrieve_marcxml # call Alma API with MMSIDs and return Array of MARCXML
  step :prepare_marcxml # massage MARCXML - for now ensure UTF-8
  step :index_via_traject, with: 'traject.index_records' # receive a IO object and do the indexing

  private

  def retrieve_marcxml(identifiers:)
    response = AlmaApi::Client.new.bibs identifiers
    docs = response['bib']&.filter_map do |bib_data|
      marcxml = bib_data['anies'].first
      marcxml.gsub('<?xml version="1.0" encoding="UTF-16"?>', '')
    end

    Success docs: docs
  end

  def prepare_marcxml(args)
    io = StringIO.new "<?xml version=\"1.0\" encoding=\"UTF-8\"?><collection>#{args[:docs].join}</collection>"

    Success(io: io)
  end
end
