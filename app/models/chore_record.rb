# frozen_string_literal: true

class ChoreRecord < ApplicationRecord
  belongs_to :chore
  belongs_to :performed_by, class_name: 'User', inverse_of: :performed_chore_records
  belongs_to :created_by, class_name: 'User', inverse_of: :created_chore_records

  validates :contribution_points, numericality: { greater_than: 0 }
  validates :performed_at, presence: true
end
