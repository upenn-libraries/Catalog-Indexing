# frozen_string_literal: true

describe AlmaApi::Client do

  describe '.bibs' do
    let(:client) { described_class.new }
    let(:bib_id) { 'sample_bib' }
    let(:marc_xml) { 'test' }

    context 'with a successful request' do

      before { stub_alma_api_bib_request(bib_id, marc_xml) }

      it 'returns the response body' do
        expect(client.bibs(bib_id)).to eq ('test')
      end
    end

    context 'with response with status 4xx-5xx' do
      before { stub_alma_api_bib_http_error(bib_id) }

      it 'raises the expected error message' do
        allow(client).to receive(:alma_bibs_error).and_return(error_code: '401652', error_message: 'General Error')
        expect {
          client.bibs(bib_id)
        }.to raise_error(AlmaApi::Client::Error, '401652: General Error')
      end
    end

    context 'when mmsids exceeds maximum allowed' do
      let(:bib_id) { (0..50).to_a }

      before { stub_alma_api_bib_request(bib_id, marc_xml) }

      it 'raises error' do
        expect {
          client.bibs(bib_id)
        }.to raise_error(AlmaApi::Client::Error,
                         'Too many mms ids provided, exceeds the maximum allowed 50.')
      end
    end
  end
end
