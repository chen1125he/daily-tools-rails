# frozen_string_literal: true

module Api
  module V1
    class TypingArticlesController < ApplicationController
      before_action :set_typing_article, only: %i[show update destroy]

      def index
        @pagy, @typing_articles = pagy(TypingArticle.order(id: :desc))
      end

      def show
        render :show
      end

      def create
        @typing_article = TypingArticle.new(typing_article_params)
        return render_validation_error(@typing_article) unless @typing_article.save

        render :show, status: :created
      end

      def update
        return render_validation_error(@typing_article) unless @typing_article.update(typing_article_params)

        render :show
      end

      def destroy
        @typing_article.destroy!
        render :show
      rescue ActiveRecord::DeleteRestrictionError
        render json: {
          error: {
            code: 'TYPING_ARTICLE_IN_USE',
            message: '该文章已有练习记录，无法删除'
          }
        }, status: :unprocessable_content
      end

      private

      def set_typing_article
        @typing_article = TypingArticle.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_not_found('TYPING_ARTICLE_NOT_FOUND', '练习文章不存在')
      end

      def typing_article_params
        params.require(:typing_article).permit(:title, :body)
      end
    end
  end
end
