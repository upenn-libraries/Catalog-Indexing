# frozen_string_literal: true

require 'dry/transaction'

# Issue request to Solr instance/collection/suggest handler to build a specified dictionary
class BuildSuggestDictionary
  include Dry::Transaction(container: Container)

  step :use_only_one_collection
  step :validate_collection, with: 'solr.validate_collections'
  step :validate_suggester_params
  step :prepare_solr_suggester_build_url
  step :prepare_solr_connection
  step :build_dictionary

  private

  # We only want to work with a single collection
  # @param collection [String]
  # @return [Dry::Monads::Result]
  def use_only_one_collection(collection:, **args)
    unless collection.is_a?(String)
      return Failure(message: 'This transaction supports only a single collection name as a string')
    end

    # validate_collections step expects an array
    Success(collections: [collection], **args)
  end

  # validate_collections

  # Make sure we have the right parameters to build the Solr URL
  # @param collections [Array] single collection to contain the suggester
  # @param suggester [String] name of suggester, as define in solr config
  # @param dictionary [String] name of dictionary, as defined in solr config
  # @return [Dry::Monads::Result]
  def validate_suggester_params(collections:, dictionary:, suggester:, **args)
    collection = collections.first
    unless collection && dictionary && suggester
      return Failure(message: 'Collection, Suggester and Dictionary names must be provided')
    end

    Success(collection: collection, dictionary: dictionary, suggester: suggester, **args)
  end

  # Construct URL for building the right suggester dictionary
  # @param collection [String] collection to contain the suggester
  # @param suggester [String] name of suggester, as defined in solr config
  # @param dictionary [String] name of dictionary, as defined in solr config
  # @return [Dry::Monads::Result]
  def prepare_solr_suggester_build_url(collection:, suggester:, dictionary:, **args)
    uri = SolrTools.suggester_uri(collection: collection, suggester: suggester, dictionary: dictionary)
    Success(url: uri.to_s, **args)
  end

  # @param url [String] URL used to build the suggester
  # @param timeout [Integer] how long, in seconds, to wait for the HTTP request to complete
  # @return [Dry::Monads::Result]
  def prepare_solr_connection(url:, timeout: 3600, **args)
    connection = SolrTools.connection url: url, timeout: timeout
    Success(connection: connection, **args)
  end

  # Tell Solr to build the suggester dictionary
  # @param connection [Faraday::Connection]
  # @return [Dry::Monads::Result]
  def build_dictionary(connection:, **_args)
    response = connection.get
    if response.success?
      Success('Suggester built successfully')
    else
      Failure(message: "Suggester build failed with response code: #{response.status}")
    end
  rescue StandardError => e
    Failure(message: "Suggester build failed with exception #{e.class.name}: #{e.message}.")
  end

  # @param response [Faraday::Response]
  # @return [Dry::Monads::Result]
  def notify(response:, **_args)
    q_time_ms = response.body.dig('responseHeader', 'QTime')
    message = "Suggester built in #{q_time_ms} ms"
    if Rails.env.production?
      Honeybadger.notify(message)
    else
      Rails.logger.debug message
    end
    Success(message)
  end
end
