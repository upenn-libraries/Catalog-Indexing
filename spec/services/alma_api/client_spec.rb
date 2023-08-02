# frozen_string_literal: true

describe AlmaApi::Client do
  include AlmaApiMocks

  describe '.bibs' do
    let(:client) { described_class.new }
    let(:bib_ids) { %w[sample_bib another_bib] }
    let(:marc_xml) { 'test' }

    context 'with a successful request' do

      before { stub_alma_api_bibs_request(bib_ids, marc_xml) }

      it 'returns the response body' do
        expect(client.bibs(bib_ids)).to eq ('test')
      end
    end

    context 'when receiving 4xx-5xx response with alma api error in payload' do
      before { stub_alma_api_bibs_http_error(bib_ids, alma_api_bibs_mock_error) }

      it 'raises the expected error message' do
        expect {
          client.bibs(bib_ids)
        }.to raise_error(AlmaApi::Client::Error,
                         'Could not retrieve bibs requested. 401652 General Error - An error has occurred')
      end
    end

    context 'when receiving error without alma api in payload' do
      before { stub_alma_api_bibs_http_error(bib_ids, nil) }

      it 'raises the expected error message' do
        expect {
          client.bibs(bib_ids)
        }.to raise_error(AlmaApi::Client::Error, 'Could not retrieve bibs requested.')
      end
    end

    context 'when mmsids exceeds maximum allowed' do
      let(:bib_ids) { (0..50).to_a }

      before { stub_alma_api_bibs_request(bib_ids, marc_xml) }

      it 'raises error' do
        expect {
          client.bibs(bib_ids)
        }.to raise_error(AlmaApi::Client::Error,
                         'Too many mms ids provided, exceeds the maximum allowed 50.')
      end
    end
  end
end
