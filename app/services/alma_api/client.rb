# frozen_string_literal: true

module AlmaApi
  # Simple API Client using Faraday to get Alma Bib records
  class Client
    MAX_BIBS_GET = 50 # 100 is Alma API max
    class Error < StandardError; end

    # Get Alma API response for provided MMS IDs, up to value of MAX_BIBS_GET
    # See https://developers.exlibrisgroup.com/alma/apis/docs/bibs/R0VUIC9hbG1hd3MvdjEvYmlicw
    # @todo: return JSON or XML?
    # @param [Array<String>] mmsids
    # @return [Object]
    def bibs(mmsids)
      # TODO: or just trim and handle validation elsewhere?
      if mmsids.length > MAX_BIBS_GET
        raise Error, "Too many mms ids provided, exceeds the maximum allowed #{MAX_BIBS_GET}."
      end

      query = { mms_id: Array.wrap(mmsids).join(','), expand: 'p_avail,e_avail', format: 'json' }

      begin
        faraday.get('/almaws/v1/bibs', query).body
      rescue Faraday::Error => e
        # alma_bibs_error(e) => {error_code:, error_message:}
        # error_code ||= e.response.status
        # error_message ||= 'Error when requesting Alma Api'
        raise Error
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

    # retrieve error code and message from alma api error response
    # @return [Hash]
    def alma_bibs_error(error)
      alma_error = error.response.body('errorList', 'error')&.first
      { error_code: alma_error&.dig('errorCode'), error_message: alma_error&.dig('errorMessage') }
    end
  end
end
