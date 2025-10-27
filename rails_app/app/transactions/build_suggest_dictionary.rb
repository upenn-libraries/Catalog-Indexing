# frozen_string_literal: true

require 'dry/transaction'

# Issue request to Solr instance/collection/suggest handler to build a specified dictionary
class BuildSuggestDictionary
  include Dry::Transaction(container: Container)

  step :validate_collection, with: 'solr.validate_collections'
  step :use_only_one_collection
  step :validate_suggester_params
  step :prepare_solr_suggester_build_url
  step :prepare_solr_connection
  step :build_dictionary

  private

  # @param collections [Array, String]
  # @return [Dry::Monads::Result]
  def use_only_one_collection(collections:, **args)
    collection = Array.wrap(collections) # Support receiving either a string or array
    return Failure(message: 'This transaction supports only a single collection name') unless collection.one?

    Success(collection: collection.first, **args)
  end

  # @param collection [String] collection to contain the suggester
  # @param suggester [String] name of suggester, as define in solr config
  # @param dictionary [String] name of dictionary, as defined in solr config
  # @return [Dry::Monads::Result]
  def validate_suggester_params(collection:, dictionary:, suggester:, **args)
    unless collection && dictionary && suggester
      return Failure(message: 'Collection, Suggester and Dictionary names must be provided')
    end

    Success(collection: collection, dictionary: dictionary, suggester: suggester, **args)
  end

  # @param collection [String] collection to contain the suggester
  # @param suggester [String] name of suggester, as define in solr config
  # @param dictionary [String] name of dictionary, as defined in solr config
  # @return [Dry::Monads::Result]
  def prepare_solr_suggester_build_url(collection:, suggester:, dictionary:, **args)
    solr_uri = URI(Settings.solr.url)
    uri_class = solr_uri.scheme == 'https' ? URI::HTTPS : URI::HTTP
    solr_suggester_build_url = uri_class.build(
      scheme: solr_uri.scheme, host: solr_uri.host, port: solr_uri.port,
      path: "/solr/#{collection}/#{suggester}", userinfo: "#{Settings.solr.user}:#{Settings.solr.password}",
      query: URI.encode_www_form('suggest.dictionary': dictionary, 'suggest.build': true)
    )
    Success(url: solr_suggester_build_url, **args)
  end

  # @return [Dry::Monads::Result]
  def prepare_solr_connection(url:, timeout: 3600, **args)
    connection = Faraday.new(url: url, request: { timeout: timeout }) do |conn|
      conn.response :raise_error
    end
    Success(connection: connection, **args)
  end

  # @return [Dry::Monads::Result]
  def build_dictionary(connection:, **_args)
    response = connection.get
    Success('Suggester built successfully') if response.success?
  rescue StandardError => e
    Failure(message: "Suggester build failed with exception #{e.class.name}: #{e.message}. Response: #{response.body}")
  end
end
