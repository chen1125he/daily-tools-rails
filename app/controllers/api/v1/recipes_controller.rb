# frozen_string_literal: true

module Api
  module V1
    class RecipesController < ApplicationController
      before_action :set_recipe, only: %i[show update destroy]

      def parse_from_text
        text = params.require(:text)
        result = Ai::RecipeParser.call(text: text, current_user: current_user)
        @recipe = reload_recipe_for_render(result[:recipe].id)
        render :show, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render_validation_error(e.record)
      rescue Ai::RecipeParser::ParseError => e
        render json: { error: { code: 'RECIPE_PARSE_FAILED', message: e.message } }, status: :unprocessable_entity
      rescue ActionController::ParameterMissing => e
        render json: { error: { code: 'INVALID_PARAMS', message: e.message } }, status: :bad_request
      end

      def index
        scope = current_user.recipes.includes(recipe_ingredients: :ingredient).order(updated_at: :desc)
        if params[:q].present?
          scope = scope.where('title ILIKE ?', "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%")
        end
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
        # 必须一次 permit 到位：若先只 permit 标量，请求里的 recipe_ingredients_attributes 会被记成 Unpermitted parameter（日志噪音且易误判）。
        params.require(:recipe).permit(
          :title,
          :prep_description,
          :cook_description,
          :prep_minutes,
          :cook_minutes,
          :nutrition,
          :source_text,
          :in_ai_plan,
          recipe_ingredients_attributes: RECIPE_INGREDIENTS_NESTED_KEYS
        )
      end
    end
  end
end
