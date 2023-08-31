# frozen_string_literal: true

# A User
class User < ApplicationRecord
  devise :rememberable, :timeoutable
  if Rails.env.development?
    devise :omniauthable, omniauth_providers: [:developer]
  else
    devise :omniauthable, omniauth_providers: []
  end

  validates :email, presence: true, uniqueness: true
  validates :uid, uniqueness: { scope: :provider }, if: :provider_provided?

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.active = true
    end
  end

  private

  # @return [TrueClass, FalseClass]
  def provider_provided?
    provider.present?
  end
end
