# frozen_string_literal: true

module Steps
  # Step to prepare MARCXML for indexing into Solr
  class PrepareMARCXML
    include Dry::Monads[:result]

    # Shove MARCXML into a XML string for a MARCXMLReader to parse into MARC::Record objects
    # @param [Array|String] docs
    # @return [Dry::Monads::Result]
    def call(docs:, **args)
      xml = Array.wrap(docs).join.gsub('<?xml version="1.0" encoding="UTF-16"?>', '')
      io = StringIO.new "<?xml version=\"1.0\" encoding=\"UTF-8\"?><collection>#{xml}</collection>"
      Success(io: io, **args)
    rescue StandardError => e
      Failure e
    end
  end
end
