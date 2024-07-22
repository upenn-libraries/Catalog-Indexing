# frozen_string_literal: true

module Steps
  # Step to get Solr collections for use with webhook indexing operations
  class GetCollections
    include Dry::Monads[:result]

    # Get the collections names either from args or from the ConfigItem
    # @option collections [Array]
    # @return [Dry::Monads::Result]
    def call(**args)
      collections = Array.wrap(args[:collections] || ConfigItem.value_for(:webhook_target_collections))
      if collections.any?
        Success(collections: collections, **args)
      else
        Failure('No target collections defined for operation.')
      end
    end
  end
end
