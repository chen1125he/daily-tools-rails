# frozen_string_literal: true

attributes :id, :user_id, :title,
           :full_recipe_text,
           :prep_description, :cook_description, :prep_minutes,
           :cook_minutes, :nutrition, :source_text, :created_at, :updated_at

child(recipe_ingredients: :recipe_ingredients) do
  extends 'api/v1/recipe_ingredients/base'
end
