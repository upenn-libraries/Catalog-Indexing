# frozen_string_literal: true

# Traject Writer class for writing to Penn Libraries Catalog Solr
class CatalogWriter < Traject::SolrJsonWriter
  # configure do
  #   settings do
  #     provide 'solr.update_url', solr_update_url
  #     provide 'solr_writer.batch_size', ENV.fetch('SOLR_WRITER_BATCH_SIZE', 250)
  #     provide 'solr_writer.thread_pool', ENV.fetch('SOLR_WRITER_THREAD_POOL', 2)
  #   end
  # end

  # TODO: dynamically set collection name?
  # TODO: embed basic auth values
  def solr_update_url; end
end
