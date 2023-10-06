# frozen_string_literal: true

module Solr
  # Thin wrapper for RSolr commands
  class QueryClient
    attr_accessor :solr, :collection

    def initialize(collection: nil)
      config = Config.new
      @collection = collection || config.collection_name
      @solr = RSolr.connect(url: config.query_url(collection: @collection))
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
      solr.post documents, add_attributes: attributes
    end

    # Delete a record by unique ID
    # @param [String] id
    # @return [RSolr::HashWithResponse]
    def delete(id:)
      solr.delete_by_id id
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
