# frozen_string_literal: true

module Api
  module V1
    class TypingErrorMarksController < ApplicationController
      def create
        practice = current_user.typing_practices.find(params[:typing_practice_id])
        if practice.completed?
          return render json: {
            error: { code: 'TYPING_PRACTICE_ALREADY_FINISHED', message: '练习已结束，无法继续记录错字' }
          }, status: :unprocessable_content
        end

        character = error_mark_params[:character]
        if character.blank?
          return render json: {
            error: { code: 'INVALID_PARAMS', message: 'character 不能为空' }
          }, status: :bad_request
        end

        @typing_error_mark = TypingErrorMark.record!(
          typing_practice: practice,
          character: character,
          wubi_code: error_mark_params[:wubi_code]
        )
        @typing_error_mark = TypingErrorMark.includes(:typing_word).find(@typing_error_mark.id)
        render :show, status: :created
      rescue ActiveRecord::RecordNotFound
        render_not_found('TYPING_PRACTICE_NOT_FOUND', '练习记录不存在')
      rescue ActiveRecord::RecordInvalid => e
        render_validation_error(e.record)
      end

      private

      def error_mark_params
        params.require(:typing_error_mark).permit(:character, :wubi_code)
      end
    end
  end
end
