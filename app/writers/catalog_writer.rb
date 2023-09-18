# frozen_string_literal: true

# Traject Writer class for writing to Penn Libraries Catalog Solr indexes
class CatalogWriter < Traject::SolrJsonWriter
  attr_accessor :solr_config, :writers

  def initialize(settings)
    @solr_config = Solr::Config.new
    settings = settings.merge({
      'solr_writer.batch_size' => ENV.fetch('SOLR_WRITER_BATCH_SIZE', 250),
      'solr_writer.thread_pool' => ENV.fetch('SOLR_WRITER_THREAD_POOL', 5),
      'solr.url' => solr_config.url
    })
    super(settings)
    build_writers_for_targets
  end

  def put(context)
    @writers.each do |writer|
      writer.put context
    end
  end

  private

  def build_writers_for_targets
    @writers = if settings['solr_writer.target_collections']&.any?
                 settings['solr_writer.target_collections'].map do |collection_name|
                  Traject::SolrJsonWriter.new(
                    {
                      'solr.update_url' => solr_config.update_url(collection: collection_name)
                    }
                  )
                 end
               else
                 [Traject::SolrJsonWriter.new(
                   {
                     'solr.update_url' => solr_config.update_url
                   }
                 )]
               end
  end
end
