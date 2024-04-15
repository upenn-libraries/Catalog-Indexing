# frozen_string_literal: true

RSpec.describe 'Webhook Indexing requests' do
  include FixtureHelpers

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

  context 'when receiving POST requests' do
    before do
      allow(ENV).to receive(:fetch).with('ALMA_WEBHOOK').and_return('test')
      allow(ENV).to receive(:fetch).with('SOLR_COLLECTION', 'catalog-indexing-test').and_return(nil)
    end

    context 'with BIB actions' do
      let(:unexpected_bib_event_json) do
        { 'action' => 'bib', 'event' => { 'value' => 'BIB_CONJURED' },
          'bib' => { 'mms_id' => '9977795539303681', 'anies' => [] } }.to_json
      end
      let(:suppressed_bib_event_json) do
        { 'action' => 'bib', 'event' => { 'value' => 'BIB_ADDED' },
          'bib' => { 'mms_id' => '9977795539303681', 'suppress_from_publishing' => true, 'anies' => [] } }.to_json
      end
      let(:unexpected_action_json) do
        { 'action' => 'UNEXPECTED', 'event' => { 'value' => 'BIB_CONJURED' },
          'bib' => { 'mms_id' => '9977795539303681', 'anies' => [] } }.to_json
      end

      before do
        allow(ConfigItem).to receive(:value_for).with(:process_bib_webhooks).and_return(true)
      end

      it 'validates message integrity' do
        post webhook_listen_path, params: unexpected_action_json, headers: { 'X-Exl-Signature': 'baaaaaaad' }
        expect(response).to have_http_status :unauthorized
      end

      it 'handles validated bib updated events' do
        headers = { 'X-Exl-Signature': 'izk27RMyBjiUl/16pJwlculiIA9/S8Ve1acxzs1m8Ag=' }
        post webhook_listen_path, params: json_fixture('bib_updated', :webhooks), headers: headers
        expect(response).to have_http_status :accepted
      end

      it 'handles validated bib added events' do
        headers = { 'X-Exl-Signature': 'DFBUc0lp/4uXQ0F0XRijTJslEHiHoqD5TQN9hRnuNjI=' }
        post webhook_listen_path, params: json_fixture('bib_created', :webhooks), headers: headers
        expect(response).to have_http_status :accepted
        expect(IndexByBibEventJob.jobs.size).to eq 1
      end

      it 'properly handles validated bib added events where the record is suppressed' do
        headers = { 'X-Exl-Signature': 'LAxz7MzFo6dow5P7x4UKJgDUL7B7+dnSsogx6WxSCys=' }
        post webhook_listen_path, params: suppressed_bib_event_json, headers: headers
        expect(response).to have_http_status :no_content
        expect(IndexByBibEventJob.jobs.size).to eq 0
      end

      it 'handles validated bib deleted events' do
        headers = { 'X-Exl-Signature': 'NTUI5p0G96iiw8vzq+7jX0U+KbxzZcbbMTIDjcwsacM=' }
        post webhook_listen_path, params: json_fixture('bib_deleted', :webhooks), headers: headers
        expect(response).to have_http_status :not_implemented
      end

      it 'handles validated requests with unexpected action' do
        headers = { 'X-Exl-Signature': 'PabrhAvogIlxlHWHrwh0VRybGvrRmJX+RQVbBkYAGdI=' }
        post webhook_listen_path, params: unexpected_action_json, headers: headers
        expect(response).to have_http_status :no_content
      end

      it 'handles validated requests with unexpected bib event' do
        headers = { 'X-Exl-Signature': '4RkSNlOHBlQGQvhvF+R+z43D0M/xzg4pHex5FJfq+3o=' }
        post webhook_listen_path, params: unexpected_bib_event_json, headers: headers
        expect(response).to have_http_status :no_content
      end

      it 'handles requests resulting in JSON parsing errors' do
        headers = { 'X-Exl-Signature': 'Va+tT44R3GjbLKPFhD8usw9zMCfzZn+MejOv9dGN9hY=' }
        post webhook_listen_path, params: 'invalid JSON', headers: headers
        expect(response).to have_http_status :unprocessable_entity
      end
    end

    context 'with JOB actions' do
      before do
        allow(ConfigItem).to receive(:value_for).with(:process_job_webhooks).and_return(true)
      end

      it 'handles validated job completed events' do
        headers = { 'X-Exl-Signature': 'e0ooQk9/vgmpK/RmdfMUz7jK0HIQkk4YDDP5dYHq+KY=' }
        post webhook_listen_path, params: json_fixture('job_end_success', :webhooks), headers: headers
        expect(response).to have_http_status :accepted
        expect(ProcessAlmaExportJob.jobs.size).to eq 1
      end
    end
  end
end
