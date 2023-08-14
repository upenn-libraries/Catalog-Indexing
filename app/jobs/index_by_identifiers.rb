# frozen_string_literal: true

# Index to Solr with MMS IDs, via Alma API and Traject
# ex mms ids: 9979201969103681, 9978929650003681
class IndexByIdentifiers
  include Sidekiq::Job

  # @param [Array] identifiers
  def perform(identifiers)
    response = AlmaApi::Client.new.bibs identifiers
    docs = response['bib']&.filter_map do |bib_data|
      marcxml = bib_data['anies'].first
      marcxml.gsub('<?xml version="1.0" encoding="UTF-16"?>', '')
    end

    # TODO: but Alma response say this is UTF-16?? but with 16 set here i get "XML parsing error: Document labelled UTF-16 but has UTF-8 content"
    io = StringIO.new "<?xml version=\"1.0\" encoding=\"UTF-8\"?><collection>#{docs.join}</collection>"

    indexer = PennMarcIndexer.new
    indexer.process_with(
      MARC::XMLReader.new(io, parser: :nokogiri, ignore_namespace: true),
      CatalogWriter.new(indexer.settings) # writer: outputs hashes/json/whatev - in the end, JSON for Solr
      # Traject::ArrayWriter.new
      # on_skipped: handle_skipped_record_proc,
      # rescue_with: rescue_error_proc
    )
  end
end
