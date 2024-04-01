# frozen_string_literal: true

# a user
class User < ApplicationRecord
  if Rails.env.development?
    devise :omniauthable, omniauth_providers: %i[developer saml]
  else
    devise :omniauthable, omniauth_providers: [:saml]
  end

  validates :email, presence: true, uniqueness: true
  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :provider, presence: true

  scope :filter_status, ->(status) { where(active: status) }

  # @param [OmniAuth::AuthHash] auth
  # @return [User, nil]
  def self.from_omniauth_developer(auth)
    return unless Rails.env.development?

    email = "#{auth.info.uid}@upenn.edu"
    where(provider: auth.provider, uid: auth.info.uid, active: true).first_or_create do |user|
      user.uid = auth.info.uid
      user.email = email
      user.active = true
    end
  end

  # @param [OmniAuth::AuthHash] auth
  # @return [User, nil]
  def self.from_omniauth_saml(auth)
    user = find_by(provider: auth.provider, uid: auth.info.uid.gsub('@upenn.edu', ''))
    return nil unless user

    user.email = auth.info.uid # update email with value from IdP, save will occur later
    user
  end
end
