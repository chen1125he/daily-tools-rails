# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_many :refresh_tokens, dependent: :destroy
  has_many :performed_chore_records, class_name: 'ChoreRecord', foreign_key: :performed_by_id, inverse_of: :performed_by, dependent: :restrict_with_exception
  has_many :created_chore_records, class_name: 'ChoreRecord', foreign_key: :created_by_id, inverse_of: :created_by, dependent: :restrict_with_exception

  validates :phone, presence: true, uniqueness: true
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validates :status, inclusion: { in: %w[active disabled] }

  scope :active, -> { where(status: 'active') }

  def active?
    status == 'active'
  end
end
