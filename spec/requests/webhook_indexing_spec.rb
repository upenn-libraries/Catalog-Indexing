# frozen_string_literal: true

RSpec.describe 'Webhook Indexing requests' do
  context 'when receiving get request' do
    it 'successfully responds' do
      get webhook_challenge_path, params: { challenge: 'test' }
      expect(response).to have_http_status :ok
    end

    it 'echos a challenge param' do
      get webhook_challenge_path, params: { challenge: 'test' }
      challenge = response.parsed_body
      expect(challenge).to eq({ 'challenge' => 'test' })
    end
  end

  context 'when receiving valid post request' do
    let(:bib_updated_json) do
      {
        'id' => '3235071115491107182',
        'action' => 'BIB',
        'institution' => { 'value' => '01UPENN_INST', 'desc' => 'University of Pennsylvania' },
        'time' => '2020-08-17T15:03:24.605Z',
        'event' => { 'value' => 'BIB_UPDATED', 'desc' => 'BIB record updated' },
        'bib' => {
          'mms_id' => '9977111159403681', 'record_format' => 'marc21', 'linked_record_id' => {
                                                                         'value' => '993400000000015976', 'type' => 'CZ'
                                                                       },
          'title' => 'Farm and Business : The Journal of the Caribbean Agro-Economic Society',
          'author' => nil, 'issn' => nil, 'isbn' => nil,
          'network_number' => %w[(CKB)3400000000015976 (EXLCZ)993400000000015976],
          'place_of_publication' => 'St. Augustine',
          'publisher_const' => 'Caribbean Agro-Economic Society',
          'holdings' =>
            { 'value' => '', 'link' => '/almaws/v1/bibs/9977111159403681/holdings' },
          'created_by' => 'NON_SFX_CREATOR', 'created_date' => '2012-02-25Z',
          'last_modified_by' => 'System', 'last_modified_date' => '2020-08-17Z',
          'suppress_from_publishing' => 'false', 'suppress_from_external_search' => 'false',
          'sync_with_oclc' => 'NONE', 'sync_with_libraries_australia' => 'NONE',
          'originating_system' => 'NON_SFX', 'originating_system_id' => '993400000000015976',
          'anies' => ['__XML__'], 'requests' => nil, 'link' => nil
        },
        'holding' => nil, 'item' => nil, 'portfolio' => nil, 'representation' => nil
      }.to_json
    end
    let(:bib_deleted_json) do
      {
        'id' => '3229093755673699933', 'action' => 'BIB',
        'institution' => { 'value' => '01UPENN_INST', 'desc' => 'University of Pennsylvania' },
        'time' => '2020-08-17T15:21:45.747Z', 'event' =>
          { 'value' => 'BIB_DELETED', 'desc' => 'BIB record deleted' },
        'bib' => {
          'mms_id' => '9977111307103681', 'record_format' => 'marc21', 'linked_record_id' =>
            { 'value' => '993780000000297684', 'type' => 'CZ' },
          'title' => 'IFPRI Discussion Papers', 'author' => nil, 'issn' => nil, 'isbn' => nil,
          'network_number' => %w[(CKB)3780000000297684 (EXLCZ)993780000000297684],
          'publisher_const' => 'International Food Policy Research Institute',
          'holdings' => {
            'value' => '', 'link' => '/almaws/v1/bibs/9977111307103681/holdings'
          },
          'created_by' => 'NON_SFX_CREATOR', 'created_date' => '2017-05-14Z',
          'last_modified_by' => 'System', 'last_modified_date' => '2020-08-17Z',
          'suppress_from_publishing' => 'false', 'suppress_from_external_search' => 'false',
          'sync_with_oclc' => 'BIBS', 'sync_with_libraries_australia' => 'NONE',
          'originating_system' => 'NON_SFX', 'originating_system_id' => '993780000000297684',
          'anies' => ['__XML__'], 'requests' => nil, 'link' => nil
        },
        'holding' => nil, 'item' => nil, 'portfolio' => nil, 'representation' => nil
      }.to_json
    end
    let(:bib_added_json) do
      {
        'id' => '7120811384122420557', 'action' => 'BIB',
        'institution' => { 'value' => '01UPENN_INST', 'desc' => 'University of Pennsylvania' },
        'time' => '2020-08-17T15:03:25.393Z', 'event' =>
          { 'value' => 'BIB_CREATED', 'desc' => 'BIB record created' },
        'bib' => {
          'mms_id' => '9977795539303681', 'record_format' => 'marc21',
          'linked_record_id' => { 'value' => '993390000000032320', 'type' => 'CZ' },
          'title' => 'Stata Journal', 'author' => nil, 'issn' => nil, 'isbn' => nil,
          'network_number' => ['(CKB)3390000000032320', '(EXLCZ)993390000000032320'],
          'holdings' => { 'value' => '', 'link' => '/almaws/v1/bibs/9977795539303681/holdings' },
          'created_by' => 'CKB', 'created_date' => '2013-05-25Z', 'last_modified_by' => 'System',
          'last_modified_date' => '2020-08-17Z', 'suppress_from_publishing' => 'false',
          'suppress_from_external_search' => 'false', 'sync_with_oclc' => 'NONE',
          'sync_with_libraries_australia' => 'NONE', 'originating_system' => 'CKB',
          'originating_system_id' => '(CKB)3390000000032320',
          'anies' => ['__XML__'], 'requests' => nil, 'link' => nil
        },
        'holding' => nil, 'item' => nil, 'portfolio' => nil, 'representation' => nil
      }.to_json
    end

    before { allow(ENV).to receive(:fetch).with('ALMA_WEBHOOK').and_return('test') }

    it 'handles validated bib updated events' do
      headers = { 'X-Exl-Signature': 'R7NdTOCOnEAfVhicWhYjEeluE9TZZM6Nusu7A4S7hQU=' }
      post webhook_listen_path, params: bib_updated_json, headers: headers
      expect(response).to have_http_status :ok
    end

    it 'handles validated bib added events' do
      headers = { 'X-Exl-Signature': 'kQJotW9Ru0Ug2ZFM9jkhnOH0TAF3dzbrp+Vi7Oggvwg=' }
      post webhook_listen_path, params: bib_added_json, headers: headers
      expect(response).to have_http_status :ok
    end

    it 'handles validated bib deleted events' do
      headers = { 'X-Exl-Signature': '8hFmGtFrxz9UY6VgFhwFd6uDmruyZdDCgSFfIQlBMLM=' }
      post webhook_listen_path, params: bib_deleted_json, headers: headers
      expect(response).to have_http_status :ok
    end
  end

  context 'when receiving invalid post request' do
    let(:unexpected_bib_event_json) do
      { 'action' => 'bib', 'event' => { 'value' => 'BIB_CONJURED' },
        'bib' => { 'mms_id' => '9977795539303681', 'anies' => [] } }.to_json
    end

    let(:unexpected_action_json) do
      { 'action' => 'UNEXPECTED', 'event' => { 'value' => 'BIB_CONJURED' },
        'bib' => { 'mms_id' => '9977795539303681', 'anies' => [] } }.to_json
    end

    before { allow(ENV).to receive(:fetch).with('ALMA_WEBHOOK').and_return('test') }

    it 'validates message integrity' do
      post webhook_listen_path, params: unexpected_action_json, headers: { 'X-Exl-Signature': 'baaaaaaad' }
      expect(response).to have_http_status :unauthorized
    end

    it 'handles validated requests with unexpected action' do
      headers = { 'X-Exl-Signature': 'PabrhAvogIlxlHWHrwh0VRybGvrRmJX+RQVbBkYAGdI=' }
      post webhook_listen_path, params: unexpected_action_json, headers: headers
      expect(response).to have_http_status :bad_request
    end

    it 'handles validated requests with unexpected bib event' do
      headers = { 'X-Exl-Signature': '4RkSNlOHBlQGQvhvF+R+z43D0M/xzg4pHex5FJfq+3o=' }
      post webhook_listen_path, params: unexpected_bib_event_json, headers: headers
      expect(response).to have_http_status :bad_request
    end
  end
end
