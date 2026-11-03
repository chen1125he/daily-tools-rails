# frozen_string_literal: true

module Api
  module V1
    class TypingErrorMarksController < ApplicationController
      def index
        @typing_error_marks = current_user.typing_error_marks
                                          .includes(:typing_word)
                                          .where('recent_mistake_count > 0')
                                          .order(recent_mistake_count: :desc, id: :desc)
                                          .limit(index_limit)
      end

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

      def clear_recent
        ids = Array(params[:ids]).map { |id| Integer(id) }
        if ids.empty?
          return render json: {
            error: { code: 'INVALID_PARAMS', message: 'ids 不能为空' }
          }, status: :bad_request
        end

        updated_count = current_user.typing_error_marks.where(id: ids)
                                    .update_all(recent_mistake_count: 0, updated_at: Time.current)
        render json: { code: 0, data: { updated_count: updated_count } }
      rescue ArgumentError, TypeError
        render json: {
          error: { code: 'INVALID_PARAMS', message: 'ids 必须是整数数组' }
        }, status: :bad_request
      end

      private

      def index_limit
        raw = params[:limit].presence || params[:n]
        return 20 if raw.blank?

        [[ raw.to_i, 1 ].max, 100 ].min
      end

      def error_mark_params
        params.require(:typing_error_mark).permit(:character)
      end
    end
  end
end
