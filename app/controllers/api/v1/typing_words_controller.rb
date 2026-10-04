# frozen_string_literal: true

module Api
  module V1
    class TypingWordsController < ApplicationController
      def lookup
        character = params[:character].to_s.strip
        if character.blank?
          return render json: {
            error: { code: 'INVALID_PARAMS', message: 'character 不能为空' }
          }, status: :bad_request
        end

        unless character.length == 1 && character.match?(/\p{Han}/)
          return render json: {
            error: { code: 'INVALID_PARAMS', message: 'character 必须是单个汉字' }
          }, status: :bad_request
        end

        @typing_word = TypingWord.lookup_wubi!(character: character)
        render :show
      rescue Ai::WubiCodeLookup::ParseError => e
        render json: { error: { code: 'WUBI_LOOKUP_FAILED', message: e.message } }, status: :unprocessable_content
      rescue ActiveRecord::RecordInvalid => e
        render_validation_error(e.record)
      end
    end
  end
end
