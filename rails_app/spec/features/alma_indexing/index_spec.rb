# frozen_string_literal: true

describe 'Alma Indexing Index Page' do
  let(:user) { create(:user) }

  context 'when submitting IDs' do
    before do
      sign_in user
      visit index_by_id_path
    end

    it 'succeeds with valid IDs' do
      fill_in 'MMS IDs', with: '1987342, 1239874'
      click_on 'Submit'

      expect(find('div.alert')).to have_text 'Indexing job enqueued.'
    end

    it 'fails with invalid IDs' do
      fill_in 'MMS IDs', with: 'test, ' * 101
      click_on 'Submit'

      expect(find('div.alert')).to have_text 'Number of MMS IDs (101) exceeds the limit (100)'
    end
  end
end
