# frozen_string_literal: true

require 'zip'

module Solr
  # Rudely appropriating PSU's delightful:
  # https://github.com/psu-libraries/scholarsphere/blob/develop/lib/scholarsphere/solr_config.rb
  class Config
    CONFIG_PATH = '/solr/admin/configs'
    COLLECTION_PATH = '/solr/admin/collections'

    def solr_username
      ENV.fetch('SOLR_USERNAME', 'admin')
    end

    def solr_password
      ENV.fetch('SOLR_PASSWORD', 'password')
    end

    def config_url
      solr_url path: CONFIG_PATH
    end

    def collection_url
      solr_url path: COLLECTION_PATH
    end

    def query_url(collection: collection_name)
      solr_url path: "/solr/#{collection}"
    end

    def update_url(collection: collection_name)
      solr_url path: "/solr/#{collection}/update/json"
    end

    def dir
      ENV.fetch('SOLR_CONFIG_DIR', 'solr/conf')
    end

    def collection_name
      ENV.fetch('SOLR_COLLECTION', "catalog-indexing-#{Rails.env}")
    end

    def num_shards
      ENV.fetch('SOLR_NUM_SHARDS', '1')
    end

    def configset_name
      # TODO: the Vagrant development environment creates the configset using this name
      # @configset_name ||= "configset-#{solr_md5}"
      'catalog-indexing'
    end

    def base_url
      ENV.fetch('SOLR_URL', 'http://localhost:8983')
    end

    def tempfile
      tmp = Tempfile.new('configset')
      Zip::File.open(tmp, Zip::File::CREATE) do |zipfile|
        Dir["#{dir}/**/**"].each do |file|
          zipfile.add(file.sub("#{dir}/", ''), file)
        end
      end
      tmp
    end

    # @return [String]
    def solr_url(path: '')
      uri = URI(base_url)
      uri.user = solr_username
      uri.password = solr_password
      uri.path = path
      uri.to_s
    end
  end
end
