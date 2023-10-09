# frozen_string_literal: true

RSpec.describe 'Relevancy Tests' do
  include_context 'with Solr queries'

  it 'empty search should include fixture doc in response' do
    resp = solr_resp_doc_ids_only({ q: '*:*' })
    expect(resp).to include('9979201969103681').as_first_result
  end
end
