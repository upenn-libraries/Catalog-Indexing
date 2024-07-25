# frozen_string_literal: true

# Stub Solr::QueryClient delete calls for collections to return success code.
shared_context 'with solr collections supporting deletes' do
  before do
    mock_client = instance_double Solr::QueryClient
    mock_response = instance_double RSolr::HashWithResponse
    allow(mock_response).to receive(:response).and_return({ status: 200 })
    allow(mock_client).to receive(:delete).and_return(mock_response)
    allow(Solr::QueryClient).to receive(:new).with(collection: collections.first).and_return(mock_client)
  end
end

# Stub Solr::QueryClient commit calls for collections to return success code.
shared_context 'with solr collections supporting commits' do
  before do
    mock_client = instance_double Solr::QueryClient
    mock_response = instance_double RSolr::HashWithResponse
    allow(mock_response).to receive(:response).and_return({ status: 200 })
    allow(mock_client).to receive(:commit).and_return(mock_response)
    collections.each do |collection|
      allow(Solr::QueryClient).to receive(:new).with(collection: collection).and_return(mock_client)
    end
  end
end
