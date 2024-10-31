# frozen_string_literal: true

describe 'Alma Indexing Index Page' do
  include AlmaApiMocks

  let(:user) { create(:user) }
  let(:id) { '9991987342' }
  let(:mock_transaction_instance) { instance_double(transaction) }

  before do
    allow(ConfigItem).to receive(:value_for).with(:adhoc_target_collections).and_return(['test-collection'])
    allow(transaction).to receive(:new).and_return(mock_transaction_instance)
    allow(mock_transaction_instance).to receive(:call).and_return(outcome)
    sign_in user
    visit adhoc_indexing_path
  end

  context 'with the add by ID form' do
    let(:transaction) { IndexByIdentifiers }

    context 'with a successful request' do
      let(:outcome) { Dry::Monads::Result::Success.new(errors: []) }

      it 'succeeds with all valid IDs' do
        within '#add-by-id-form' do
          fill_in 'MMS IDs to Add or Update via Bibs API', with: id
          click_on 'Submit'
        end
        expect(page).to have_text "Sent updates to Solr for #{id}"
      end
    end

    context 'with an unsuccessful request' do
      let(:outcome) { Dry::Monads::Result::Failure.new(AlmaApi::Client::Error.new) }

      it 'fails with too many IDs' do
        within '#add-by-id-form' do
          fill_in 'MMS IDs to Add', with: 'test, ' * 101
          click_on 'Submit'
        end
        expect(page).to have_text 'Number of MMS IDs (101) exceeds the limit (100)'
      end
    end
  end

  context 'with the delete by ID form' do
    let(:transaction) { DeleteByIdentifiers }

    before do
      within '#delete-by-id-form' do
        fill_in 'MMS IDs to delete', with: id
        click_on 'Submit'
      end
    end

    context 'with a successful request' do
      let(:outcome) { Dry::Monads::Result::Success.new(errors: "Record(s) #{id} removed from Solr") }

      it 'succeeds with all valid IDs' do
        expect(page).to have_text "Record(s) #{id} removed from Solr"
      end
    end

    context 'with an unsuccessful request' do
      let(:outcome) { Dry::Monads::Result::Failure.new(exception: StandardError.new('Solr problem')) }

      it 'fails with invalid IDs' do
        expect(page).to have_text 'Solr problem'
      end
    end
  end
end
