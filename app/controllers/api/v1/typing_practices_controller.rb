# frozen_string_literal: true

module Api
  module V1
    class TypingPracticesController < ApplicationController
      before_action :set_typing_practice, only: %i[show start complete]

      def index
        scope = current_user.typing_practices.includes(:typing_article, typing_error_marks: :typing_word)
        scope = scope.where(typing_article_id: params[:typing_article_id]) if params[:typing_article_id].present?
        @pagy, @typing_practices = pagy(scope.order(created_at: :desc, id: :desc))
      end

      def show
        render :show
      end

      def create
        @typing_practice = current_user.typing_practices.build(create_params)
        return render_validation_error(@typing_practice) unless @typing_practice.save

        @typing_practice = reload_practice(@typing_practice.id)
        render :show, status: :created
      end

      def start
        @typing_practice.start!
        @typing_practice = reload_practice(@typing_practice.id)
        render :show
      rescue ActiveRecord::RecordInvalid => e
        render_validation_error(e.record)
      end

      def complete
        typed_body = params.require(:typing_practice).require(:typed_body)
        @typing_practice.complete!(typed_body: typed_body)
        @typing_practice = reload_practice(@typing_practice.id)
        render :show
      rescue ActiveRecord::RecordInvalid => e
        render_validation_error(e.record)
      rescue ActionController::ParameterMissing => e
        render json: { error: { code: 'INVALID_PARAMS', message: e.message } }, status: :bad_request
      end

      private

      def set_typing_practice
        @typing_practice = reload_practice(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_not_found('TYPING_PRACTICE_NOT_FOUND', '练习记录不存在')
      end

      def reload_practice(id)
        current_user.typing_practices.includes(:typing_article, typing_error_marks: :typing_word).find(id)
      end

      def create_params
        params.require(:typing_practice).permit(:typing_article_id)
      end
    end
  end
end
