# frozen_string_literal: true

module AlmaApi
  class Client
    MAX_BIBS_GET = 50 # 100 is Alma API max

    # Get Alma API response for provided MMS IDs, up to value of MAX_BIBS_GET
    # @todo: return JSON or XML?
    # @param [Array<String>] mmsids
    # @return [Object]
    def bibs(mmsids)
      raise if mmsids.length > MAX_BIBS_GET # TODO: or just trim and handle validation elsewhere?

      query = { mms_id: Array.wrap(mmsids).join(','), expand: 'p_avail,e_avail', format: 'json' }
      faraday.get('/almaws/v1/bibs', query).body
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
  end
end
