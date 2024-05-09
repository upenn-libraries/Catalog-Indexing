# frozen_string_literal: true

# Traject Writer class for writing to (potentially more than one) Penn Libraries Catalog Solr index
class MultiCollectionWriter < Traject::SolrJsonWriter
  attr_accessor :writers, :collections

  # @param [Array] collections
  # @param [Hash] settings
  def initialize(collections, settings = {})
    @collections = Array.wrap(collections)
    settings = settings.merge({ 'solr_writer.batch_size' => ENV.fetch('SOLR_WRITER_BATCH_SIZE', 250),
                                'solr_writer.thread_pool' => 0, # manage concurrency on our own
                                'solr.url' => SolrTools.solr_url_with_auth })
    super(settings)
    build_writers_for_targets
  end

  # delegate calls to sub-writers
  def put(context)
    @writers.each do |writer|
      writer.put context
    end
  end

  def commit(query_params = nil)
    @writers.each do |writer|
      writer.commit(query_params)
    end
  end

  def close
    @writers.each(&:close)
  end

  private

  def build_writers_for_targets
    # Ensure settings are propagated to sub-writers
    @writers = collections.map do |collection_name|
      Traject::SolrJsonWriter.new(settings.merge({ 'solr.update_url' => update_url(collection_name) }))
    end
  end

  # @param collection [String]
  # @return [String] solr update URL with auth params embedded
  def update_url(collection)
    SolrTools.collection_update_url_with_auth(collection: collection)
  end
end
