# frozen_string_literal: true

module Api
  module V1
    class MenusController < ApplicationController
      before_action :set_menu, only: %i[show update destroy]

      def index
        scope = current_user.menus.includes(menu_recipes: { recipe: { recipe_ingredients: :ingredient } })
        scope = apply_index_filters(scope)
        @pagy, @menus = pagy(scope.order(menu_date: :desc, meal_type: :asc))
      end

      def show
        render :show
      end

      def create
        @menu = current_user.menus.build(menu_attributes)
        @menu.save!
        @menu = reload_menu_for_render(@menu.id)
        render :show, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render_validation_error(e.record)
      end

      def update
        raise ActiveRecord::RecordInvalid, @menu unless @menu.update(menu_attributes)

        @menu = reload_menu_for_render(@menu.id)
        render :show
      rescue ActiveRecord::RecordInvalid => e
        render_validation_error(e.record)
      end

      def destroy
        @menu.destroy!
        render :show
      end

      def generate
        Ai::MenuPlanner.call(
          current_user: current_user,
          days: params[:days],
          start_date: params[:start_date],
          custom_prompt: params[:custom_prompt]
        )
        render_api_success(nil, status: :created)
      rescue Ai::MenuPlanner::ParseError => e
        render json: { error: { code: 'MENU_PLAN_FAILED', message: e.message } }, status: :unprocessable_entity
      rescue ActionController::ParameterMissing => e
        render json: { error: { code: 'INVALID_PARAMS', message: e.message } }, status: :bad_request
      end

      private

      def set_menu
        @menu = reload_menu_for_render(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_not_found('MENU_NOT_FOUND', '菜单不存在')
      end

      def reload_menu_for_render(id)
        current_user.menus.includes(menu_recipes: { recipe: { recipe_ingredients: :ingredient } }).find(id)
      end

      def apply_index_filters(scope)
        scope = scope.where(menu_date: params[:menu_date]) if params[:menu_date].present?
        scope = scope.where(meal_type: params[:meal_type]) if params[:meal_type].present?

        if params[:from].present? && params[:to].present?
          scope.where(menu_date: params[:from]..params[:to])
        elsif params[:from].present?
          scope.where(menu_date: params[:from]..)
        elsif params[:to].present?
          scope.where(menu_date: ..params[:to])
        else
          scope
        end
      end

      def menu_attributes
        params.require(:menu).permit(:menu_date, :meal_type, recipe_ids: [])
      end
    end
  end
end
