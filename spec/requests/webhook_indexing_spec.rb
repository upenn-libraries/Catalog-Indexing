# frozen_string_literal: true

RSpec.describe 'Webhook Indexing requests' do
  include FixtureHelpers

  let(:unexpected_bib_event_json) do
    { 'action' => 'bib', 'event' => { 'value' => 'BIB_CONJURED' },
      'bib' => { 'mms_id' => '9977795539303681', 'anies' => [] } }.to_json
  end
  let(:unexpected_action_json) do
    { 'action' => 'UNEXPECTED', 'event' => { 'value' => 'BIB_CONJURED' },
      'bib' => { 'mms_id' => '9977795539303681', 'anies' => [] } }.to_json
  end

  after do
    Sidekiq::Worker.clear_all
  end

  context 'when receiving GET request' do
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

  context 'when receiving POST request' do
    before { allow(ENV).to receive(:fetch).with('ALMA_WEBHOOK').and_return('test') }

    it 'validates message integrity' do
      post webhook_listen_path, params: unexpected_action_json, headers: { 'X-Exl-Signature': 'baaaaaaad' }
      expect(response).to have_http_status :unauthorized
    end

    it 'handles validated bib updated events' do
      headers = { 'X-Exl-Signature': 'izk27RMyBjiUl/16pJwlculiIA9/S8Ve1acxzs1m8Ag=' }
      post webhook_listen_path, params: json_fixture('bib_updated'), headers: headers
      expect(response).to have_http_status :ok
    end

    it 'handles validated bib added events' do
      headers = { 'X-Exl-Signature': 'DFBUc0lp/4uXQ0F0XRijTJslEHiHoqD5TQN9hRnuNjI=' }
      post webhook_listen_path, params: json_fixture('bib_created'), headers: headers
      expect(response).to have_http_status :ok
    end

    it 'handles validated bib deleted events' do
      headers = { 'X-Exl-Signature': 'NTUI5p0G96iiw8vzq+7jX0U+KbxzZcbbMTIDjcwsacM=' }
      post webhook_listen_path, params: json_fixture('bib_deleted'), headers: headers
      expect(response).to have_http_status :ok
    end

    it 'handles validated job completed events' do
      headers = { 'X-Exl-Signature': 'e0ooQk9/vgmpK/RmdfMUz7jK0HIQkk4YDDP5dYHq+KY=' }
      post webhook_listen_path, params: json_fixture('job_end_success'), headers: headers
      expect(response).to have_http_status :ok
      expect(ProcessPublishJob.jobs.size).to eq 1
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
