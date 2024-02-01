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
      conf.create_collection
    end

    attr_reader :config

    def initialize(config = Config.new)
      @config = config
    end

    def zip_file
      File.open(config.tempfile)
    end

    def all_collections
      collections
    end

    def collection_exists?(name: config.collection_name)
      collections.include?(name)
    end

    def delete_collection(name: config.collection_name)
      resp = connection.get(Config::COLLECTION_PATH, action: 'DELETE', name: name)
      check_resp(resp)
    end

    def delete_all_collections
      collections.map { |collection| delete_collection(name: collection) }
    end

    def create_collection(name: config.collection_name, configset: config.configset_name)
      resp = connection.get(Config::COLLECTION_PATH,
                            action: 'CREATE',
                            name: name,
                            numShards: config.num_shards,
                            'collection.configName': configset)
      check_resp(resp)
    end

    def modify_collection(configset: config.configset_name)
      resp = connection.get(Config::COLLECTION_PATH,
                            action: 'MODIFYCOLLECTION',
                            collection: config.collection_name,
                            'collection.configName': configset)
      check_resp(resp)
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
      @connection ||= Faraday.new(config.base_url) do |faraday|
        faraday.request :authorization, :basic, Settings.solr.user, Settings.solr.password
        faraday.adapter :net_http
      end
    end

    def collections
      resp = connection.get(Config::COLLECTION_PATH, action: 'LIST')
      JSON.parse(resp.body)['collections']
    end
  end
end
