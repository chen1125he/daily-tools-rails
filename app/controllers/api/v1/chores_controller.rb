# frozen_string_literal: true

module Api
  module V1
    class ChoresController < ApplicationController
      before_action :set_chore, only: %i[show update]

      def index
        chores = Chore.order(:name)
        chores = chores.where(active: cast_boolean(params[:active])) if params.key?(:active)

        render json: { data: chores.map { |chore| chore_payload(chore) } }, status: :ok
      end

      def create
        chore = Chore.new(chore_params)
        return render_validation_error(chore) unless chore.save

        render json: { data: chore_payload(chore) }, status: :created
      end

      def show
        render json: { data: chore_payload(@chore) }, status: :ok
      end

      def update
        return render_validation_error(@chore) unless @chore.update(chore_params)

        render json: { data: chore_payload(@chore) }, status: :ok
      end

      private

      def set_chore
        @chore = Chore.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_not_found('CHORE_NOT_FOUND', '家务类型不存在')
      end

      def chore_params
        params.permit(:name, :active, :description, :default_contribution_points)
      end

      def chore_payload(chore)
        {
          id: chore.id,
          name: chore.name,
          active: chore.active,
          description: chore.description,
          default_contribution_points: chore.default_contribution_points&.to_f
        }
      end

      def cast_boolean(value)
        ActiveModel::Type::Boolean.new.cast(value)
      end

      def render_not_found(code, message)
        render json: { error: { code: code, message: message } }, status: :not_found
      end

      def render_validation_error(record)
        render json: {
          error: {
            code: 'VALIDATION_FAILED',
            message: record.errors.full_messages.to_sentence,
            details: record.errors.to_hash
          }
        }, status: :unprocessable_content
      end
    end
  end
end
