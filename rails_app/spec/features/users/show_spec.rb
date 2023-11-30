# frozen_string_literal: true

describe 'User show page' do
  let(:user) { create(:user) }

  before { sign_in user }

  context 'when viewing user show page' do
    before { visit user_path(user) }

    it 'displays email' do
      within('.user-list') do
        expect(find('.email')).to have_text(user.email)
      end
    end

    it 'displays active status' do
      within('.user-list') do
        expect(find('.active')).to have_text('Active')
      end
    end

    it 'displays created_at' do
      within('.user-list') do
        expect(find('.created-at')).to have_text(user.created_at.to_fs(:display))
      end
    end
  end
end
