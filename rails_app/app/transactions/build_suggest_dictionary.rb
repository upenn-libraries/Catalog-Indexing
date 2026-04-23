# frozen_string_literal: true

require 'dry/transaction'
require 'benchmark'

# Issue request to Solr instance/collection/suggest handler to build a specified dictionary
class BuildSuggestDictionary
  include Dry::Transaction(container: Container)
  include ActionView::Helpers::DateHelper

  SUGGESTER_BUILD_TIMEOUT_SECONDS = 3600

  step :get_target_collections, with: 'config_item.incremental_target_collections'
  step :validate_config_collections, with: 'solr.validate_collections'
  step :validate_suggester_params
  step :compose_build_urls_for_collections
  step :execute_suggester_builds_in_serial
  step :notify

  private

  # Ensure we have the parameters required to build the Solr suggester URLs.
  #
  # @param collections [Array<String>] collections we want to build the suggester for
  # @param dictionary [String] name of dictionary, as defined in config
  # @param suggester [String] name of suggester, as defined in config
  # @return [Dry::Monads::Result]
  def validate_suggester_params(collections:, dictionary:, suggester:, **args)
    unless collections.any? && dictionary.present? && suggester.present?
      return Failure(message: 'Collection, Suggester and Dictionary names must be provided')
    end

    Success(collections: collections, dictionary: dictionary, suggester: suggester, **args)
  end

  # Build a hash mapping each collection to its array of Solr suggester build URLs.
  #
  # Working syntax, staging example:
  #   http://catalog-manager-stg01.library.upenn.int/solr1/catalog-staging/suggest?suggest.build=true&distrib=false
  #
  # @param collections [Array<String>] collections we want to build the suggester for
  # @return [Dry::Monads::Result]
  def compose_build_urls_for_collections(collections:, suggester:, dictionary:, **args)
    collection_build_urls = collections.each_with_object({}) do |collection, map|
      map[collection] = Settings.solr.nodes.map do |node|
        SolrTools.suggester_build_url(suggester: suggester, dictionary: dictionary, node: node, collection: collection)
      end
    end

    Success(collection_build_urls: collection_build_urls, suggester: suggester, **args)
  rescue StandardError => e
    Failure(message: "Could not compose suggester build URLs: #{e.message}")
  end

  # Tell Solr to build the suggester dictionary on each node.
  #
  # @param collection_build_urls [Hash{String => Array<String>}] map of collection name to build URLs
  # @return [Dry::Monads::Result]
  def execute_suggester_builds_in_serial(collection_build_urls:, **args)
    build_time_in_sec = Benchmark.realtime do
      collection_build_urls.each_value do |urls|
        urls.each do |url|
          response = perform_build_request(url)
          raise StandardError, "Solr build call #{url} failed: #{response.body}" unless response.success?
        end
      end
    end

    Success(build_time_in_sec: build_time_in_sec, suggester: args[:suggester], **args)
  rescue StandardError => e
    Failure(message: "Problem building suggester: #{e.message}")
  end

  # Notify via Slack (or log in non-production environments) that the suggester build has completed.
  #
  # @param build_time_in_sec [Float] elapsed build time in seconds
  # @param suggester [String] name of the suggester that was built
  # @return [Dry::Monads::Result]
  def notify(build_time_in_sec:, suggester:, **_args)
    build_time_humanized = distance_of_time_in_words(Time.zone.now, Time.zone.now + build_time_in_sec.seconds)
    message = "`#{suggester}` suggester built in #{build_time_humanized}."
    if Rails.env.test? || Rails.env.development?
      Rails.logger.debug message
    else
      SendSlackNotificationJob.perform_async(message)
    end
    Success(message)
  end

  # @param url [String] URL for suggester build
  # @return [Faraday::Response]
  def perform_build_request(url)
    Faraday.get(url) do |req|
      req.headers['Authorization'] = Faraday::Utils.basic_header_from(Settings.solr.user, Settings.solr.password)
      req.options.timeout = SUGGESTER_BUILD_TIMEOUT_SECONDS
      req.options.open_timeout = 10
    end
  end
end
