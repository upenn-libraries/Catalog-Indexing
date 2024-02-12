# frozen_string_literal: true

describe 'Omniauth Callbacks Requests' do

  context 'with SAML authentication' do
    before do
      OmniAuth.config.mock_auth[:saml] = OmniAuth::AuthHash.new(
        { provider: 'saml', info: OmniAuth::AuthHash::InfoHash.new({ uid: user.uid }) }
      )
      post user_saml_omniauth_callback_path
    end

    context 'when the user exists and is active' do
      let(:user) { create :user, :saml }

      it 'displays success message' do
        follow_redirect!
        expect(response.body).to include(I18n.t('devise.omniauth_callbacks.success', kind: 'SAML'))
      end
    end

    context 'when the user exists but is inactive' do
      let(:user) { create :user, :saml, :inactive }

      it 'displays inactive message' do
        follow_redirect!
        expect(response.body).to include(I18n.t('devise.omniauth_callbacks.inactive'))
      end
    end

    context 'when the user is not persisted in the database' do
      let(:user) { build(:user, :saml) }

      it 'displays no access message' do
        follow_redirect!
        expect(response.body).to include(I18n.t('devise.omniauth_callbacks.no_access'))
      end
    end
  end
end
