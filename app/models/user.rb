# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_many :refresh_tokens, dependent: :destroy

  validates :phone, presence: true, uniqueness: true
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validates :status, inclusion: { in: %w[active disabled] }

  scope :active, -> { where(status: 'active') }

  def active?
    status == 'active'
  end
end
