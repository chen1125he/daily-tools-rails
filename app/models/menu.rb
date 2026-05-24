# frozen_string_literal: true

class Menu < ApplicationRecord
  # breakfast: 早餐, lunch: 午餐, dinner: 晚餐
  enum :meal_type, { breakfast: 0, lunch: 1, dinner: 2 }

  belongs_to :user
  belongs_to :menu_plan, optional: true

  has_many :menu_recipes, -> { order(:id) }, dependent: :destroy, inverse_of: :menu
  has_many :recipes, through: :menu_recipes

  validates :menu_date, presence: true
  validates :meal_type, presence: true
end
