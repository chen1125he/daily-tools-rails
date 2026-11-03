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

        @typing_word = TypingWord.find_by(character: character)
        unless @typing_word
          return render json: {
            error: { code: 'TYPING_WORD_NOT_FOUND', message: '未找到该汉字的五笔编码' }
          }, status: :not_found
        end

        render :show
      end
    end
  end
end
