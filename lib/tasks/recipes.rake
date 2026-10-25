# frozen_string_literal: true

namespace :recipes do
  desc '导出菜谱到'
  task :export, [ :path ] => :environment do |_task, args|
    Recipe.all.map do |recipe|
      {
        title: recipe.title,
        prep_minutes: recipe.prep_minutes,
        cook_minutes: recipe.cook_minutes,
        prep_description: recipe.prep_description,
        cook_description: recipe.cook_description,
        nutrition: recipe.nutrition,
        recipe_ingredients: recipe.recipe_ingredients.map do |recipe_ingredient|
          ingredient = recipe_ingredient.ingredient
          {
            name: ingredient.name,
            search_keywords: ingredient.search_keywords,
            role: recipe_ingredient.role,
            amount: recipe_ingredient.amount
          }
        end
      }
    end
  end

  desc '从 JSON 导入菜谱。'
  task :import, [ :path ] => :environment do |_task, args|
    data.each do |recipe|
      recipe_ingredients = recipe.dup.delete(:recipe_ingredients)
      r = Recipe.find_or_initialize_by(title: recipe[:title])
      r.user = User.first
      r.assign_attributes(recipe.except(:recipe_ingredients))
      r.save!

      recipe_ingredients.each do |recipe_ingredient|
        ingredient = Ingredient.find_or_initialize_by(name: recipe_ingredient[:name])
        ingredient.assign_attributes(search_keywords: recipe_ingredient[:search_keywords])
        ingredient.save!

        ri = RecipeIngredient.find_or_initialize_by(recipe: r, ingredient: ingredient)
        ri.assign_attributes(amount: recipe_ingredient[:amount], role: recipe_ingredient[:role])
        ri.save!
      end
    end
  end
end
