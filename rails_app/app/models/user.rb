# frozen_string_literal: true

# a user
class User < ApplicationRecord
  if Rails.env.development?
    devise :omniauthable, omniauth_providers: %i[developer saml]
  else
    devise :omniauthable, omniauth_providers: [:saml]
  end

  validates :email, presence: true, uniqueness: true
  validates :uid, uniqueness: { scope: :provider }, if: :provider_provided?

  scope :filter_status, ->(status) { where(active: status) }

  # @param [OmniAuth::AuthHash] auth
  # @return [User, nil]
  def self.from_omniauth_developer(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.active = true
    end
  end

  # @param [OmniAuth::AuthHash] auth
  # @return [User, nil]
  def self.from_omniauth_saml(auth)
    where(provider: auth.provider, uid: auth.info.uid.gsub('@upenn.edu', '')).first_or_initialize do |user|
      user.email = auth.info.uid
    end
  end


  private

  # @return [TrueClass, FalseClass]
  def provider_provided?
    provider.present?
  end
end
