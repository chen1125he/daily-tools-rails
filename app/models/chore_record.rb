# frozen_string_literal: true

class ChoreRecord < ApplicationRecord
  enum :chore_type, { catalog: 'catalog', custom: 'custom' }

  belongs_to :chore, optional: true
  belongs_to :performer, class_name: 'User', inverse_of: :performed_chore_records
  belongs_to :creator, class_name: 'User', inverse_of: :created_chore_records

  validates :points, numericality: { greater_than_or_equal_to: 0 }
  validates :performed_at, presence: true
  validates :custom_chore_name, presence: true, if: :custom?
  validate :catalog_chore_required

  def display_chore_name
    custom? ? custom_chore_name : chore&.name
  end

  private

  def catalog_chore_required
    return unless catalog?

    errors.add(:chore, '不能为空') if chore_id.blank?
  end
end
