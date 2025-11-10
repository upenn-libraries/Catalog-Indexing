# frozen_string_literal: true

# Wrappers for Solr API calls
class SolrTools
  DEFAULT_CONNECTION_TIMEOUT_SECONDS = 60

  class CommandError < StandardError; end

  class << self
    # @param url [String]
    # @param timeout [Integer]
    # @return [Faraday::Connection]
    def connection(url: base_url, timeout: DEFAULT_CONNECTION_TIMEOUT_SECONDS)
      Faraday.new(url, request: { timeout: timeout }) do |faraday|
        faraday.request :authorization, :basic, Settings.solr.user, Settings.solr.password
        faraday.adapter :net_http
        # faraday.response :raise_error
        # Use rails logger and filter out sensitive information
        faraday.response :logger, Rails.logger, headers: true, bodies: false, log_level: :info do |fmt|
          # TODO: sanitize logged URL that contains basic auth creds?
          # fmt.filter(APPROPRIATE_REGEX_TO_REMOVE_URL_CREDS, '\1[REDACTED]')
        end
        faraday.response :json
      end
    end

    # @return [String (frozen)]
    def default_collection
      'catalog-indexing'
    end

    # @return [Array<String>]
    def collections
      resp = connection.get(collections_url, action: 'LIST')
      resp.body['collections']
    end

    # @return [String (frozen)]
    def new_collection_name
      "#{Settings.solr.collection_name_prefix}#{DateTime.current.strftime('%Y%m%d')}"
    end

    # @return [String]
    def base_url
      Settings.solr.url
    end

    # @return [String (frozen)]
    def collections_url
      "#{Settings.solr.url}/solr/admin/collections"
    end

    # Return a URI object for a solr suggester request
    # @param collection [String]
    # @param suggester [String]
    # @param dictionary [String]
    # @param build [Boolean]
    # @param query [String, NilClass]
    # @return [String]
    def suggester_url(suggester:, dictionary:, collection: default_collection, build: false, query: nil)
      solr_uri = URI(Settings.solr.url)
      query_params = { 'suggest.dictionary': dictionary, 'suggest.build': build, q: query }
      URI::Generic.build(
        scheme: solr_uri.scheme, host: solr_uri.host, port: solr_uri.port,
        path: "/solr/#{collection}/#{suggester}",
        query: URI.encode_www_form(query_params.compact)
      ).to_s
    end

    # @param [String] collection_name
    # @return [Boolean]
    def collection_exists?(collection_name)
      collections.include? collection_name
    end

    # @param [String] collection_name
    # @raise [SolrTools::CommandError]
    # @return [Faraday::Response]
    def create_collection(collection_name)
      raise CommandError, 'Insufficient configuration to create a collection' unless collections_settings_present?

      response = connection.get('/solr/admin/collections',
                                action: 'CREATE', name: collection_name,
                                numShards: Settings.solr.shards, replicationFactor: Settings.solr.replicas,
                                'collection.configName': Settings.solr.configset)
      raise CommandError, "Solr command failed with response: #{response.body}" unless response.success?
    end

    def delete_collection(collection_name)
      response = connection.get(collections_url, action: 'DELETE', name: collection_name)
      raise CommandError, "Solr command failed with response: #{response.body}" unless response.success?
    end

    # @note used in contexts where the above Faraday connection is not used (Traject)
    # @param [String (frozen)] path
    # @return [String]
    def solr_url_with_auth(path: '')
      uri = URI(base_url)
      uri.user = Settings.solr.user
      uri.password = Settings.solr.password
      uri.path = path
      uri.to_s
    end

    # @note used in contexts where the above Faraday connection is not used (Traject)
    # @param collection [String]
    # @return [String]
    def collection_update_url_with_auth(collection:)
      solr_url_with_auth path: "/solr/#{collection}/update/json"
    end

    # @note used in contexts where the above Faraday connection is not used (Traject)
    # @param collection [String]
    # @return [String]
    def collection_query_url_with_auth(collection:)
      solr_url_with_auth path: "/solr/#{collection}"
    end

    # Used to package configset for Rake task
    # @return [Tempfile]
    def configset_zipfile
      dir = ENV.fetch('SOLR_CONFIG_DIR', 'solr/conf')
      tmp = Tempfile.new('configset')
      Zip::File.open(tmp, Zip::File::CREATE) do |zipfile|
        Dir["#{dir}/**/**"].each do |file|
          zipfile.add(file.sub("#{dir}/", ''), file)
        end
      end
      tmp
    end

    # Use Solr Config admin API to load a new configset into Solr. Intended for use with #package_configset util
    # @param name [String] intended name of configset in Solr
    # @param path [String] location of packaged configset on the system
    def load_configset(name, path)
      outcome = connection.post('/solr/admin/configs') do |req|
        req.params = { action: 'UPLOAD', name: name }
        req.headers['Content-Type'] = 'octect/stream'
        req.body = File.read(path)
      end
      raise CommandError, "Solr command failed with response: #{outcome.body}" unless outcome.success?
    end

    # @return [Boolean]
    def collections_settings_present?
      Settings.solr.shards.present? && Settings.solr.replicas.present? && Settings.solr.configset.present?
    end
  end
end
