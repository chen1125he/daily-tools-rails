# frozen_string_literal: true

class RecipeIngredient < ApplicationRecord
  # main: 主料, side: 辅料, condiment: 调料
  enum :role, { main: 0, side: 1, condiment: 2 }

  belongs_to :recipe, inverse_of: :recipe_ingredients
  belongs_to :ingredient

  validates :role, presence: true
  validates :ingredient_id, uniqueness: { scope: :recipe_id }, unless: :marked_for_destruction?
end
