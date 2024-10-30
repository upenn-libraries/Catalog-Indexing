# frozen_string_literal: true

describe 'Alma Indexing Index Page' do
  include AlmaApiMocks

  let(:user) { create(:user) }
  let(:id) { %w[9991987342] }
  let(:response) { file_ }

  before do
    allow(ConfigItem).to receive(:value_for).with(:adhoc_target_collections).and_return(['1234'])
    stub_bibs_request ids, response
    sign_in user
    visit adhoc_indexing_path
  end

  it 'succeeds with valid IDs' do
    within '#add-by-id-form' do
      fill_in 'MMS IDs to Add or Update via Bibs API', with: id
      click_on 'Submit'
    end

    expect(page).to have_text "Sent updates to Solr for #{id}"
  end

  it 'fails with invalid IDs' do
    within '#add-by-id-form' do
      fill_in 'MMS IDs to Add', with: 'test, ' * 101
      click_on 'Submit'
    end

    expect(page).to have_text 'Number of MMS IDs (101) exceeds the limit (100)'
  end
end
