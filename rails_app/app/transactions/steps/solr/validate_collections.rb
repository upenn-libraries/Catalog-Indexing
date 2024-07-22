# frozen_string_literal: true

module Steps
  module Solr
    # Check and ensure that collections are present and exist
    class ValidateCollections
      include Dry::Monads[:result]

      # @param collections [Array<String>] collections to validate
      # @return [Dry::Monads::Result]
      def call(collections:, **args)
        return Failure('No target collections configured!') if collections.empty?

        collections.each do |collection|
          unless SolrTools.collection_exists? collection
            return Failure("Configured incremental target collection '#{collection}' does not exist.")
          end
        end

        Success(**args)
      end
    end
  end
end
