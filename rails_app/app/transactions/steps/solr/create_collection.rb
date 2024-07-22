# frozen_string_literal: true

module Steps
  module Solr
    # Step to create a new Solr collection
    class CreateCollection
      include Dry::Monads[:result]

      # Create a new collection, defaulting to SolrTools.new_collection_name
      # @param collection_name [String]
      # @return [Dry::Monads::Result]
      def call(collection_name: SolrTools.new_collection_name, **args)
        if SolrTools.collection_exists?(collection_name)
          return Failure("Solr collection #{collection_name} already exists. Something is going wrong.")
        end

        SolrTools.create_collection(collection_name)
        Success(collection: collection_name, **args)
      rescue SolrTools::CommandError => e
        Failure("Could not create new Solr collection '#{collection_name}': #{e.message}.")
      rescue StandardError => e
        Failure("Unexpected error (#{e.class.name}) during Solr prep: #{e.message}")
      end
    end
  end
end
