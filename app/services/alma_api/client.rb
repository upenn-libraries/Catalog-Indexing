# frozen_string_literal: true

module AlmaApi
  # Simple API Client using Faraday to get Alma Bib records
  class Client
    MAX_BIBS_GET = 100 # 100 is Alma API max
    class Error < StandardError; end

    # Get Alma API response for provided MMS IDs, up to value of MAX_BIBS_GET
    # See https://developers.exlibrisgroup.com/alma/apis/docs/bibs/R0VUIC9hbG1hd3MvdjEvYmlicw for alma bibs api
    # documentation
    # @todo: return JSON or XML?
    # @param [Array<String>] mmsids
    # @return [Object]
    def bibs(mmsids)
      if mmsids.length > MAX_BIBS_GET
        raise Error, "Too many MMS IDs provided, exceeds the maximum allowed of #{MAX_BIBS_GET}."
      end

      filtered_mmsids = Array.wrap(mmsids.select { |id| valid_mmsid?(id) })
      query = { mms_id: filtered_mmsids.join(','), expand: 'p_avail,e_avail', format: 'json' }
      begin
        JSON.parse(faraday.get('/almaws/v1/bibs', query).body)
      rescue Faraday::Error => e
        alma_error = alma_bibs_error(e)
        alma_error_code = alma_error.fetch('errorCode', nil)
        alma_error_message = alma_error.fetch('errorMessage', nil)
        raise Error, "Could not retrieve bibs requested. #{alma_error_code} #{alma_error_message}".strip
      end
    end

    private

    # @note one day we might want to pull from staging Alma via distinct API key...
    # @return [Faraday::Connection]
    def faraday
      @faraday ||= begin
        options = { request: {} } # TODO: configure timeouts, etc.
        Faraday.new(url: 'https://api-na.hosted.exlibrisgroup.com', **options) do |config|
          config.request :authorization, :apikey, Rails.application.credentials.alma_api_key
          config.request :json
          config.response :raise_error
          config.response :logger, Rails.logger, headers: true, bodies: true, log_level: :debug do |fmt|
            fmt.filter(/^(Authorization: ).*$/i, '\1[REDACTED]')
          end
          config.adapter :net_http
        end
      end
    end

    # Retrieve error code and message from alma api error response
    # We configured Faraday to automatically raise exceptions on 4xx-5xx responses. Alma Api errors are passed to these
    # exceptions, and located in the body of the Faraday::Error response object.
    # See https://developers.exlibrisgroup.com/alma/apis/docs/bibs/R0VUIC9hbG1hd3MvdjEvYmlicw for alma bibs api error
    # structure
    # @param [Faraday::Error] error
    # @return [Hash]
    def alma_bibs_error(error)
      body = JSON.parse(error.response_body) if error.response_body
      body&.dig('errorList', 'error')&.first || {}
    end

    # Alma MMS IDs start with 99 (to indicate a Bib record)
    def valid_mmsid?(mmsid)
      mmsid.starts_with?('99')
    end
  end
end
