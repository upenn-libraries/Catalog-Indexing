# frozen_string_literal: true

describe 'User Index page' do
  let(:user) { create(:user) }
  let(:inactive_user) { create(:user, :inactive, uid: 'some_dev', email: 'some_dev@library.upenn.edu') }

  before { login_as user }

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
        expect(find('.created-at')).to have_text(user.created_at.to_fs(:display))
      end
    end

    context 'with User filtering and searching' do
      it 'filters by status' do
        select 'Active', from: 'Status'
        click_on 'Filter'
        expect(page).to have_css '.user-row', count: 1
        expect(page).not_to have_text inactive_user.email
      end
    end
  end
end
