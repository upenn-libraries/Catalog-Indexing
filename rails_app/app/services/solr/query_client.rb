# frozen_string_literal: true

module Solr
  # Thin wrapper for RSolr commands
  class QueryClient
    attr_reader :solr, :collection

    def initialize(collection:)
      @collection = collection
      @solr = RSolr.connect(url: SolrTools.collection_query_url_with_auth(collection: collection))
    end

    # Perform a query
    # @param [Hash] params
    # @return [RSolr::HashWithResponse]
    def get(params:, handler: 'select')
      params[:wt] = :ruby
      solr.get handler, params: params
    end

    # @param [String] id
    # @return [RSolr::HashWithResponse]
    def get_by_id(id)
      get params: { q: "id:#{id}" }
    end

    # Add documents to the collection
    # @param [Hash, Array<Hash>] docs
    # @param [Hash] attributes
    # @return [RSolr::HashWithResponse]
    def add(docs:, attributes: {})
      documents = Array.wrap(docs)
      solr.add documents, add_attributes: attributes
    end

    # Delete records by ID
    # @param ids [String, Array]
    # @param args [Hash] extra parameters for Solr request
    # @return [RSolr::HashWithResponse]
    def delete(ids:, args: {})
      solr.delete_by_id Array.wrap(ids), args
    end

    # Delete all records in the collection
    # @return [RSolr::HashWithResponse]
    def delete_all
      solr.delete_by_query '*:*'
    end

    # Force a commit
    # @param [Hash] attributes
    # @return [RSolr::HashWithResponse]
    def commit(attributes: {})
      solr.commit commit_attributes: attributes
    end
  end
end
