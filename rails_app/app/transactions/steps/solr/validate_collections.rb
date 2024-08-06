# frozen_string_literal: true

module Steps
  module Solr
    # Check and ensure that collections are present and exist
    class ValidateCollections
      include Dry::Monads[:result]

      # @option collections [Array<String>] collections to validate
      # @return [Dry::Monads::Result]
      def call(args)
        collections = args[:collections]
        return Failure(message: 'No target collections configured!') if collections.empty?

        collections.each do |collection|
          unless SolrTools.collection_exists? collection
            return Failure(message: "Collection '#{collection}' does not exist.")
          end
        end
        Success(collections: collections, **args)
      end
    end
  end
end
