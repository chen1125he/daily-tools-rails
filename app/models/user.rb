# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_many :refresh_tokens, dependent: :destroy
  has_many :performed_chore_records, class_name: 'ChoreRecord', foreign_key: :performer_id, inverse_of: :performer, dependent: :restrict_with_exception
  has_many :created_chore_records, class_name: 'ChoreRecord', foreign_key: :creator_id, inverse_of: :creator, dependent: :restrict_with_exception
  has_many :recipes, dependent: :destroy
  has_many :menus, dependent: :destroy

  validates :phone, presence: true, uniqueness: true
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validates :status, inclusion: { in: %w[active disabled] }

  scope :active, -> { where(status: 'active') }

  def active?
    status == 'active'
  end
end
