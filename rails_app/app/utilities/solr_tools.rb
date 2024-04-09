# frozen_string_literal: true

# Wrappers for Solr API calls
class SolrTools
  class CommandError < StandardError; end

  # Known Needed

  # tempfile (aka configset as a ZIP - for use in Find development)
  # collection_name - return name of "the" Solr collection. adapting this depends on context
  # delete_collection - used only in specs


  class << self

    def connection
      Faraday.new(base_url) do |faraday|
        faraday.request :authorization, :basic, Settings.solr.username, Settings.solr.password
        faraday.adapter :net_http
      end
    end

    def collections
      resp = connection.get(collection_path, action: 'LIST')
      JSON.parse(resp.body)['collections']
    end

    def base_url
      Settings.solr.url
    end

    def collections_url
      "#{Settings.solr.url}/solr/admin/collections"
    end

    def collection_exists?(collection_name)
      list = connection.get('/solr/admin/collections', action: 'LIST')
      configsets = JSON.parse(list.body)['collections']
      configsets.include? collection_name
    end

    def create_collection(collection_name)
      response = connection.get('/solr/admin/collections',
                                action: 'CREATE', name: collection_name,
                                numShards: Settings.solr.shards, 'collection.configName': Settings.solr.configset)
      raise CommandError, "Solr command failed with response: #{response.body}" unless response.success?
    end

    # Used in contexts where the above Faraday connection is not used (Traject)
    def solr_url_with_auth(path: '')
      uri = URI(base_url)
      uri.user = Settings.solr.user
      uri.password = Settings.solr.password
      uri.path = path
      uri.to_s
    end

    # @param collection [String]
    def collection_update_url_with_auth(collection:)
      solr_url_with_auth path: "/solr/#{collection}/update/json"
    end
  end
end
