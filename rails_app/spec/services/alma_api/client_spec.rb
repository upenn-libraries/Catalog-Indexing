# frozen_string_literal: true

describe AlmaApi::Client do
  include AlmaApiMocks
  include FixtureHelpers

  let(:client) { described_class.new }

  describe '.bibs' do
    let(:bib_ids) { %w[99123456 99456789] }
    let(:response) { '{}' }

    context 'with a successful request' do
      before { stub_bibs_request(bib_ids, response) }

      it 'returns the response body' do
        expect(client.bibs(bib_ids)).to eq JSON.parse(response)
      end
    end

    context 'when receiving 4xx-5xx response with alma api error in payload' do
      before { stub_bibs_http_error(bib_ids, alma_api_mock_error) }

      it 'raises error with the expected message' do
        expect {
          client.bibs(bib_ids)
        }.to raise_error(AlmaApi::Client::Error,
                         'Alma API error: 401652 General Error - An error has occurred')
      end
    end

    context 'when rescuing error without alma api in payload' do
      before { stub_bibs_http_error(bib_ids, nil) }

      it 'raises error with the expected message' do
        expect {
          client.bibs(bib_ids)
        }.to raise_error(AlmaApi::Client::Error,
                         'Alma API error: Sadly error code and message are not available.')
      end
    end

    context 'when bib ids exceeds maximum allowed' do
      let(:bib_ids) { '9979201969103681' * 50 }

      before { stub_bibs_request(bib_ids, response) }

      it 'raises error' do
        expect {
          client.bibs(bib_ids)
        }.to raise_error(AlmaApi::Client::Error,
                         'Too many MMS IDs provided, exceeds the maximum allowed of 100.')
      end
    end
  end

  describe '.set_members' do
    context 'with a successful request' do
      let(:set_id) { '9912033073503681' }

      before do
        stub_set_members_success(set_id, json_fixture('set_members_get_success_p1', 'alma_api'))
        stub_set_members_success(set_id, json_fixture('set_members_get_success_p2', 'alma_api'), offset: 1)
      end

      it 'returns aggregated results from multiple calls' do
        response = client.set_members(set_id, limit: 1)
        expect(response.length).to eq 2
        expect(response.first.keys).to include 'id', 'description', 'link'
      end
    end
  end
end
