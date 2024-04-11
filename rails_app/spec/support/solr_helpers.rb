# frozen_string_literal: true

# Helper methods for clearing out and creating collections during testing
module SolrHelpers
  def test_collection
    ENV.fetch('SOLR_TEST_COLLECTION', 'catalog-indexing-test')
  end

  # Creates a set of collections in the SolrCloud
  # @param [String|Array<String>] names
  def create_collections(names)
    collection_names = Array.wrap names
    collection_names.map do |name|
      SolrTools.delete_collection(name) if SolrTools.collection_exists?(name)
      SolrTools.create_collection name
    end
  end

  # Removes a collection from the SolrCloud
  # @param [String|Array<String>] names
  def remove_collections(names)
    collection_names = Array.wrap names
    collection_names.map do |name|
      SolrTools.delete_collection(name) if SolrTools.collection_exists?(name)
    end
  end

  # Removes all records from given collection
  # @param [String|Array<String>] names
  def clear_collections(names = [test_collection])
    collection_names = Array.wrap names
    collection_names.each do |name|
      query_client = Solr::QueryClient.new(collection: name)
      query_client.delete_all
      query_client.commit
    end
  end
end
