# frozen_string_literal: true

require 'dry/transaction'

# Issue request to Solr instance/collection/suggest handler to build a specified dictionary
class BuildSuggestDictionary
  include Dry::Transaction(container: Container)

  step :validate_collection, with: 'solr.validate_collection'
  step :use_only_one_collection
  step :prepare_solr_suggester_build_url
  step :prepare_solr_connection
  step :build_dictionary

  private

  def use_only_one_collection(collections, **args)
    return Failure(message: 'This transaction supports only a single collection name') unless collections.one?

    Success(collection: collections.first, **args)
  end

  def prepare_solr_suggester_build_url(collection:, suggester:, dictionary:, **_args)
    unless collection && dictionary && suggester
      return Failure(message: 'Collection, Suggester and Dictionary names must be provided')
    end

    solr_url = URI::HTTPS.build(
      host: Settings.solr.url,
      path: "/solr/#{collection}/#{suggester}",
      query: URI.encode_www_form('suggest.dictionary': dictionary, 'suggest.build': true)
    )
    Success(url: solr_url)
  end

  def prepare_solr_connection(url:, timeout: 3600, **args)
    connection = Faraday.new(url: url, request: { timeout: timeout }, response: :raise_error)
    Success(connection: connection, **args)
  end

  def build_dictionary(connection:, **_args)
    response = connection.get
    return Success('Suggester built successfully') if response.success?

    Failure(message: "Suggester build failed. Response: #{response.body}")
  rescue StandardError => e
    Failure(message: "Suggester build failed with exception #{e.class.name}: #{e.message}")
  end
end
