# frozen_string_literal: true

attributes :id, :user_id, :menu_date, :meal_type, :created_at, :updated_at

child(recipes: :recipes) do
  extends 'api/v1/recipes/base'
end
