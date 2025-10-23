# frozen_string_literal: true

# Builds title suggest dictionary using the single collection name specified as the parameter
class BuildTitleSuggestDictionaryJob < TransactionJob
  sidekiq_options queue: 'high'

  # @param [String] collection_name
  def transaction(collection_name)
    BuildSuggestDictionary.new.call(
      collections: [collection_name]
    )
  end
end
