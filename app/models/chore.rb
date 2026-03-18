# frozen_string_literal: true

class Chore < ApplicationRecord
  has_many :chore_records, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :active, -> { where(active: true) }
end
