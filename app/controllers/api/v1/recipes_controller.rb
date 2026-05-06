# frozen_string_literal: true

module Api
  module V1
    class RecipesController < ApplicationController
      before_action :set_recipe, only: %i[show update destroy]

      def index
        scope = current_user.recipes.includes(recipe_ingredients: :ingredient).order(updated_at: :desc)
        @pagy, @recipes = pagy(scope)
      end

      def show
        render :show
      end

      def create
        @recipe = current_user.recipes.build(recipe_params)
        @recipe.save!
        @recipe = reload_recipe_for_render(@recipe.id)
        render :show, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render_validation_error(e.record)
      end

      def update
        raise ActiveRecord::RecordInvalid, @recipe unless @recipe.update(recipe_params)

        @recipe = reload_recipe_for_render(@recipe.id)
        render :show
      rescue ActiveRecord::RecordInvalid => e
        render_validation_error(e.record)
      end

      def destroy
        @recipe.destroy!
        render :show
      end

      private

      def set_recipe
        @recipe = current_user.recipes.includes(recipe_ingredients: :ingredient).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_not_found('RECIPE_NOT_FOUND', '食谱不存在')
      end

      def reload_recipe_for_render(id)
        current_user.recipes.includes(recipe_ingredients: :ingredient).find(id)
      end

      RECIPE_INGREDIENTS_NESTED_KEYS = %i[id ingredient_id role amount _destroy].freeze

      def recipe_params
        root = params.require(:recipe)
        permitted_scalar = root.permit(
          :title,
          :prep_description,
          :cook_description,
          :prep_minutes,
          :cook_minutes,
          :nutrition,
          :source_text
        )

        nested =
          if root.key?(:recipe_ingredients_attributes) || root.key?('recipe_ingredients_attributes')
            root.permit(recipe_ingredients_attributes: RECIPE_INGREDIENTS_NESTED_KEYS)[:recipe_ingredients_attributes]
          elsif root.key?(:recipe_ingredients) || root.key?('recipe_ingredients')
            # 兼容旧字段名（语义与 recipe_ingredients_attributes 相同）
            root.permit(recipe_ingredients: RECIPE_INGREDIENTS_NESTED_KEYS)[:recipe_ingredients]
          end

        return permitted_scalar if nested.nil?

        permitted_scalar.merge(recipe_ingredients_attributes: nested)
      end
    end
  end
end
