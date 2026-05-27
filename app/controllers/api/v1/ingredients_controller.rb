# frozen_string_literal: true

module Api
  module V1
    class IngredientsController < ApplicationController
      before_action :set_ingredient, only: %i[show update destroy]

      def index
        @pagy, @ingredients = pagy(Ingredient.order(:name))
      end

      def show
        render :show
      end

      def create
        @ingredient = Ingredient.new(ingredient_params)
        return render_validation_error(@ingredient) unless @ingredient.save

        render :show, status: :created
      end

      def update
        return render_validation_error(@ingredient) unless @ingredient.update(ingredient_params)

        render :show
      end

      def destroy
        @ingredient.destroy!
        render :show
      rescue ActiveRecord::DeleteRestrictionError
        render_in_use_error
      end

      private

      def set_ingredient
        @ingredient = Ingredient.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_not_found('INGREDIENT_NOT_FOUND', '食材不存在')
      end

      def ingredient_params
        params.require(:ingredient).permit(:name, :search_keywords)
      end

      def render_in_use_error
        render json: {
          error: {
            code: 'INGREDIENT_IN_USE',
            message: '该食材已被菜谱引用，无法删除'
          }
        }, status: :unprocessable_content
      end
    end
  end
end
