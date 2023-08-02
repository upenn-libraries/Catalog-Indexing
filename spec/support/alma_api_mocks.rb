# frozen_string_literal: true

# Contains helper methods to stub Alma Api requests
module AlmaApiMocks
  # @param [Array<String>] bib_ids list of mms ids of alma bibliographic record
  # @param [String] alma_marc_xml MARC XML of given record
  # @param [String] alma_api_key key to authorize alma api request
  # @return [WebMock::RequestStub]
  def stub_alma_api_request(bib_ids, alma_marc_xml, alma_api_key = '')
    bib_ids = Array.wrap(bib_ids).join(',')
    stub_request(
      :get,
      "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/?mms_id=#{bib_ids}&expand=p_avail&apikey=#{alma_api_key}"
    ).to_return(body: alma_marc_xml)
  end

  # @param [String] bib_ids list of mms ids of alma bibliographic record
  # @param [String] alma_marc_xml MARC XML of given record
  # @return [WebMock::RequestStub]
  def stub_alma_api_bibs_request(bib_ids, alma_marc_xml)
    bib_ids = Array.wrap(bib_ids).join(',')
    stub_request(
      :get,
      "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail&format=json&mms_id=#{bib_ids}"
    )
      .to_return(status: 200, body: alma_marc_xml)
  end

  # @return [WebMock::RequestStub]
  def stub_alma_api_bibs_not_found(bib_ids)
    bib_ids = Array.wrap(bib_ids).join(',')
    stub_request(
      :get,
      "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail&format=json&mms_id=#{bib_ids}"
    )
      .to_return(status: 200,
                 body: '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><bibs total_record_count="0"/>')
  end

  # @return [WebMock::RequestStub]
  def stub_alma_api_invalid_xml
    stub_request(
      :get,
      'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail&mms_id=0000000001'
    )
      .to_return(status: 200,
                 body: 'this is not valid XML')
  end

  # @param [String] bib_ids list of mms ids of alma bibliographic record
  # @param [String] body the body of the http response
  # @return [WebMock::RequestStub]
  def stub_alma_api_bib_http_error(bib_ids)
    stub_request(
      :get,
      "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail&format=json&mms_id=#{bib_ids}"
    ).to_raise(Faraday::Error)
  end

  # @return [String]
  def alma_api_bibs_mock_error
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
end
