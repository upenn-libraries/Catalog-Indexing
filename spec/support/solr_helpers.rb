# frozen_string_literal: true

# Helper methods for clearing out and creating collections during testing
module SolrHelpers
  # @param [String|Array<String>] names
  def create_collections(names = Solr::Config.new.collection_name)
    collection_names = Array.wrap names
    admin = Solr::Admin.new
    collection_names.map do |name|
      admin.delete_collection(name: name) if admin.collection_exists?(name: name)
      admin.create_collection name: name
    end
  end

  # @param [String|Array<String>] names
  def remove_collections(names = Solr::Config.new.collection_name)
    collection_names = Array.wrap names
    admin = Solr::Admin.new
    collection_names.map do |name|
      admin.delete_collection(name: name) if admin.collection_exists?(name: name)
    end
  end

  # @param [String|Array<String>] names
  def clear_collections(names = Solr::Config.new.collection_name)
    collection_names = Array.wrap names
    collection_names.each do |name|
      query_client = Solr::QueryClient.new(collection: name)
      query_client.delete_all
      query_client.commit
    end
  end
end
