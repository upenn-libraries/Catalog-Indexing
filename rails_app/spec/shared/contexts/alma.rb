# frozen_string_literal: true

# Stub request for successful Alma request.
shared_context 'with successful Alma request to get XML from IDs' do
  let(:bibnumber) { '9979201969103681' }

  before do
    stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail&format=json' \
                        "&mms_id=#{bibnumber}").to_return(status: 200, body: '', headers: {})
  end
end
