# frozen_string_literal: true

describe 'Omniauth Callbacks Requests' do
  let(:user) { build(:user) }

  context 'with saml authentication' do
    # context 'when the user has an Alma account' do
    #   before do
    #     allow(User).to receive(:new).and_return(user)
    #     allow(user).to receive(:exists_in_alma?).and_return(true)
    #
    #     post user_saml_omniauth_callback_path
    #   end
    #
    #   it 'returns success message' do
    #     follow_redirect!
    #     expect(response.body).to include(I18n.t('devise.omniauth_callbacks.success', kind: 'saml'))
    #   end
    #
    #   it 'creates a user' do
    #     expect(User.all.count).to eq 1
    #   end
    # end
  end
end
