# frozen_string_literal: true

# Contains helper methods to stub Alma Api requests
module AlmaApiMocks
  # @param [Array<String>] bib_ids list of mms ids of alma bibliographic record
  # @param [String] alma_marc_xml MARC XML of given record
  # @param [String] alma_api_key key to authorize alma api request
  # @return [WebMock::RequestStub]
  # def stub_bibs_request(bib_ids, alma_marc_xml, alma_api_key = '')
  #   bib_ids = Array.wrap(bib_ids).join(',')
  #   stub_request(
  #     :get,
  #     "#{alma_api_base_url}bibs/?mms_id=#{bib_ids}&expand=p_avail&apikey=#{alma_api_key}"
  #   ).to_return(body: alma_marc_xml)
  # end

  # @param [Array<String>] bib_ids list of mms ids of alma bibliographic record
  # @param [String] alma_marc_xml MARC XML of given record
  # @return [WebMock::RequestStub]
  def stub_bibs_request(bib_ids, alma_marc_xml)
    bib_ids = Array.wrap(bib_ids).join(',')
    stub_request(:get, "#{alma_api_base_url}bibs?expand=p_avail,e_avail&format=json&mms_id=#{bib_ids}")
      .to_return(status: 200, body: alma_marc_xml)
  end

  # @param [Array<String>] bib_ids list of mms ids of alma bibliographic record
  # @return [WebMock::RequestStub]
  def stub_bibs_not_found(bib_ids)
    bib_ids = Array.wrap(bib_ids).join(',')
    stub_request(:get, "#{alma_api_base_url}bibs?expand=p_avail,e_avail&format=json&mms_id=#{bib_ids}")
      .to_return(status: 200,
                 body: '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><bibs total_record_count="0"/>')
  end

  # @return [WebMock::RequestStub]
  def stub_bibs_invalid_xml
    stub_request(:get, "#{alma_api_base_url}bibs?expand=p_avail&mms_id=0000000001")
      .to_return(status: 200, body: 'this is not valid XML')
  end

  # @param [Array<String>] bib_ids list of mms ids of alma bibliographic record
  # @param [String] body the body of the http response
  # @return [WebMock::RequestStub]
  def stub_bibs_http_error(bib_ids, body)
    bib_ids = Array.wrap(bib_ids).join(',')
    stub_request(:get, "#{alma_api_base_url}bibs?expand=p_avail,e_avail&format=json&mms_id=#{bib_ids}")
      .to_raise(Faraday::Error.new('some exception', { body: body }))
  end

  # @param [String] set_id
  # @param [Integer] limit
  # @param [Integer] offset
  # @return [WebMock::RequestStub]
  def stub_set_members_success(set_id, body, limit: 1, offset: 0)
    stub_request(
      :get,
      "#{alma_api_base_url}conf/sets/#{set_id}/members?format=json&limit=#{limit}&offset=#{offset}"
    ).to_return(status: 200, body: body)
  end

  # Mock alma api error
  # @return [String]
  def alma_api_mock_error
    JSON.generate({
                    errorsExist: true,
                    errorList: {
                      error: [{
                        errorCode: '401652',
                        errorMessage: 'General Error - An error has occurred'
                      }]
                    }
                  })
  end

  # @return [String (frozen)]
  def alma_api_base_url
    'https://api-na.hosted.exlibrisgroup.com/almaws/v1/'
  end
end
