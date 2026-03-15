# frozen_string_literal: true

module Api
  module V1
    class ChoreRecordsController < ApplicationController
      before_action :set_chore_record, only: %i[show update destroy]

      def index
        records = ChoreRecord.includes(:chore, :performed_by, :created_by)
        records = apply_filters(records)
        records = records.order(performed_at: :desc, id: :desc)

        page = [params.fetch(:page, 1).to_i, 1].max
        per_page = [[params.fetch(:per_page, 20).to_i, 1].max, 100].min
        total = records.count
        paginated = records.offset((page - 1) * per_page).limit(per_page)

        render json: {
          data: paginated.map { |record| record_payload(record) },
          meta: {
            page: page,
            per_page: per_page,
            total: total
          }
        }, status: :ok
      end

      def show
        render json: { data: record_payload(@chore_record) }, status: :ok
      end

      def create
        created_by_id = create_params[:created_by_id] || current_user.id
        result = ChoreRecords::CreateFromText.call(
          text: create_params[:text],
          created_by_id: created_by_id,
          current_user: current_user
        )
        return render_create_error(result) unless result.success?

        render json: { data: record_payload(result.record), meta: result.meta }, status: :created
      end

      def update
        return render_validation_error(@chore_record) unless @chore_record.update(update_params)

        render json: { data: record_payload(@chore_record) }, status: :ok
      end

      def destroy
        @chore_record.destroy!
        head :no_content
      end

      private

      def set_chore_record
        @chore_record = ChoreRecord.includes(:chore, :performed_by, :created_by).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_not_found('CHORE_RECORD_NOT_FOUND', '家务记录不存在')
      end

      def apply_filters(records)
        scoped = records
        scoped = scoped.where(performed_by_id: params[:performed_by_id]) if params[:performed_by_id].present?
        scoped = scoped.where(chore_id: params[:chore_id]) if params[:chore_id].present?
        performed_from = parse_time(params[:performed_from])
        performed_to = parse_time(params[:performed_to])
        scoped = scoped.where('performed_at >= ?', performed_from) if performed_from
        scoped = scoped.where('performed_at <= ?', performed_to) if performed_to
        return scoped if params[:chore_name].blank?

        scoped.joins(:chore).where('chores.name ILIKE ?', "%#{params[:chore_name]}%")
      end

      def parse_time(value)
        Time.zone.parse(value)
      rescue ArgumentError, TypeError
        nil
      end

      def create_params
        params.permit(:text, :created_by_id)
      end

      def update_params
        params.permit(:performed_by_id, :chore_id, :contribution_points, :performed_at)
      end

      def render_create_error(result)
        render json: {
          error: {
            code: result.error_code,
            message: result.error_message,
            details: result.errors
          }
        }, status: :unprocessable_content
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

      def record_payload(record)
        {
          id: record.id,
          chore_id: record.chore_id,
          chore_name: record.chore.name,
          performed_by_id: record.performed_by_id,
          performed_by_name: record.performed_by.name,
          created_by_id: record.created_by_id,
          contribution_points: record.contribution_points.to_f,
          performed_at: record.performed_at.iso8601,
          source_text: record.source_text
        }
      end
    end
  end
end
