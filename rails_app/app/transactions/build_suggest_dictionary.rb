# frozen_string_literal: true

require 'dry/transaction'

# Issue request to Solr instance/collection/suggest handler to build a specified dictionary
class BuildSuggestDictionary
  include Dry::Transaction(container: Container)

  step :validate_collection, with: 'solr.validate_collections'
  step :use_only_one_collection
  step :prepare_solr_suggester_build_url
  step :prepare_solr_connection
  step :build_dictionary

  private

  def use_only_one_collection(collections:, **args)
    return Failure(message: 'This transaction supports only a single collection name') unless collections.one?

    Success(collection: collections.first, **args)
  end

  def prepare_solr_suggester_build_url(collection:, suggester:, dictionary:, **_args)
    unless collection && dictionary && suggester
      return Failure(message: 'Collection, Suggester and Dictionary names must be provided')
    end

    solr_uri = URI(Settings.solr.url)
    uri_class = solr_uri.scheme == 'https' ? URI::HTTPS : URI::HTTP
    solr_suggester_build_url = uri_class.build(
      scheme: solr_uri.scheme, host: solr_uri.host, port: solr_uri.port,
      path: "/solr/#{collection}/#{suggester}", userinfo: "#{Settings.solr.user}:#{Settings.solr.password}",
      query: URI.encode_www_form('suggest.dictionary': dictionary, 'suggest.build': true)
    )
    Success(url: solr_suggester_build_url, **_args)
  end

  def prepare_solr_connection(url:, timeout: 3600, **_args)
    connection = Faraday.new(url: url, request: { timeout: timeout }) do |conn|
      conn.response :raise_error
    end
    Success(connection: connection, **_args)
  end

  def build_dictionary(connection:, **_args)
    response = connection.get
    return Success('Suggester built successfully') if response.success?

  rescue StandardError => e
    Failure(message: "Suggester build failed with exception #{e.class.name}: #{e.message}. Response: #{response.body}")
  end
end
