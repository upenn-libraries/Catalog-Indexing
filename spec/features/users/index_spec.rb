# frozen_string_literal: true

describe 'User Index page' do
  let(:user) { create(:user) }
  let(:inactive_user) { create(:user, identifier: 'some_dev@library.upenn.edu', active: false) }

  before { sign_in user }

  context 'when viewing Users Index page' do
    before do
      inactive_user
      visit users_path
    end

    it 'lists all Users' do
      expect(page).to have_css('.user-row', count: User.count)
    end

    it 'displays email' do
      within(".user-row.row-id-#{user.id}") do
        expect(find('.email')).to have_link(user.email)
      end
    end

    it 'displays "Active" when active is true' do
      within(".user-row.row-id-#{user.id}") do
        expect(find('.active')).to have_text('Active')
      end
    end

    it 'displays "Inactive" when active is false' do
      within(".user-row.row-id-#{inactive_user.id}") do
        expect(find('.active')).to have_text('Inactive')
      end
    end

    it 'displays created_at' do
      within(".user-row.row-id-#{user.id}") do
        expect(find('.created-at')).to have_text(user.created_at.strftime('%B %d, %Y %I:%M %p'))
      end
    end
  end
end
