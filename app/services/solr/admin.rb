# frozen_string_literal: true

require 'solr/config'

module Solr
  # Rudely appropriating PSU's delightful:
  # https://github.com/psu-libraries/scholarsphere/blob/develop/lib/scholarsphere/solr_admin.rb
  class Admin
    class Error < StandardError; end

    def self.reset
      conf = new
      conf.delete_all_collections
      conf.delete_all_configsets
      conf.upload_config
      conf.create_collection
    end

    attr_reader :config

    def initialize(config = Config.new)
      @config = config
    end

    def zip_file
      File.open(config.tempfile)
    end

    def configset_exists?
      config_sets.include?(config.configset_name)
    end

    def delete_configset(set = config.configset_name)
      resp = connection.get(Config::CONFIG_PATH, action: 'DELETE', name: set)
      check_resp(resp)
    end

    def delete_all_configsets
      config_sets
        .reject { |set| set == '_default' }
        .map { |set| delete_configset(set) }
    end

    def all_collections
      collections
    end

    def collection_exists?(name: config.collection_name)
      collections.include?(name)
    end

    def delete_collection(collection = config.collection_name)
      resp = connection.get(Config::COLLECTION_PATH, action: 'DELETE', name: collection)
      check_resp(resp)
    end

    def delete_all_collections
      collections.map { |collection| delete_collection(collection) }
    end

    def create_collection(name: config.collection_name, configset: config.configset_name)
      resp = connection.get(Config::COLLECTION_PATH,
                            action: 'CREATE',
                            name: name,
                            numShards: config.num_shards,
                            'collection.configName': configset)
      check_resp(resp)
    end

    def modify_collection
      resp = connection.get(Config::COLLECTION_PATH,
                            action: 'MODIFYCOLLECTION',
                            collection: config.collection_name,
                            'collection.configName': config.configset_name)
      check_resp(resp)
    end

    def upload_config
      resp = connection.post(Config::CONFIG_PATH) do |req|
        req.params = { action: 'UPLOAD', name: config.configset_name }
        req.headers['Content-Type'] = 'octect/stream'
        req.body = raw_data
      end
      check_resp(resp)
    end

    def rsolr_conn(collection_name)
      @solr ||= RSolr.connect connection, :url => connection_with_collection(collection_name)
    end

    private

    def raw_data
      @raw_data ||= zip_file.read
    end

    # Gets a response object, if it's status code is not 200, we emit the body and bail
    def check_resp(resp)
      return if resp.status == 200

      begin
        body = JSON.parse(resp.body)
      rescue JSON::ParserError => _e
        raise Error, 'Request to Solr failed.'
      end
      raise Error,
            "Request to Solr failed with code #{body&.dig('error', 'code')}: #{body&.dig('error', 'msg')}"
    end

    def connection
      @connection ||= Faraday.new(config.url) do |faraday|
        if config.solr_username && config.solr_password
          faraday.request :authorization, :basic, config.solr_username, config.solr_password
        end
        # faraday.request :multipart
        faraday.adapter :net_http
      end
    end

    def connection_with_collection(collection_name)
      connection_url = connection.url_prefix.to_s
      connection_url + "solr/#{collection_name}"
    end

    def config_sets
      list = connection.get(Config::CONFIG_PATH, action: 'LIST')
      JSON.parse(list.body)['configSets']
    end

    def collections
      resp = connection.get(Config::COLLECTION_PATH, action: 'LIST')
      JSON.parse(resp.body)['collections']
    end
  end
end
