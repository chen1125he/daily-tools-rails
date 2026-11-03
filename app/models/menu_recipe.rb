# frozen_string_literal: true

class MenuRecipe < ApplicationRecord
  belongs_to :menu, inverse_of: :menu_recipes
  belongs_to :recipe

  validates :recipe_id, uniqueness: { scope: :menu_id }
end
