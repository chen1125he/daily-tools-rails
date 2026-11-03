# frozen_string_literal: true

module Api
  module V1
    class TypingErrorMarksController < ApplicationController
      def create
        character = error_mark_params[:character]
        if character.blank?
          return render json: {
            error: { code: 'INVALID_PARAMS', message: 'character 不能为空' }
          }, status: :bad_request
        end

        @typing_error_mark = TypingErrorMark.record!(
          user: current_user,
          character: character
        )
        @typing_error_mark = TypingErrorMark.includes(:typing_word).find(@typing_error_mark.id)
        render :show, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render_validation_error(e.record)
      end

      private

      def error_mark_params
        params.require(:typing_error_mark).permit(:character)
      end
    end
  end
end
