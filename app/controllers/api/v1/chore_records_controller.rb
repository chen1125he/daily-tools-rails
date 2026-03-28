# frozen_string_literal: true

module Api
  module V1
    class ChoreRecordsController < ApplicationController
      before_action :set_chore_record, only: %i[show update destroy]

      def index
        records = ChoreRecord.includes(:chore, :performer, :creator)
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

      def parse_from_text
        params.permit!
        parse_payload = Ai::ChoreRecordParser.call(text: params[:text], current_user: current_user)

        @chore_record = ChoreRecord.create!(
          chore_type: parse_payload[:chore_type],
          chore_id: parse_payload[:chore_id],
          custom_chore_name: parse_payload[:custom_chore_name],
          points: parse_payload[:points],
          performer_id: parse_payload[:performer_id],
          performed_at: parse_payload[:performed_at],
          source_text: params[:text],
          creator_id: current_user.id,
          ai_parse_payload: parse_payload[:ai_parse_payload]
        )

        render :show
      rescue ActiveRecord::RecordInvalid => e
        render_validation_error(e.record)
      end

      def create
        # TODO: 实现手动创建家务记录
        render json: { data: record_payload(@chore_record) }, status: :created
      end

      def update
        return render_validation_error(@chore_record) unless @chore_record.update(update_params)

        render :show
      end

      def destroy
        @chore_record.destroy!
        head :no_content
      end

      private

      def set_chore_record
        @chore_record = ChoreRecord.includes(:chore, :performer, :creator).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_not_found('CHORE_RECORD_NOT_FOUND', '家务记录不存在')
      end

      def apply_filters(records)
        scoped = records
        scoped = scoped.where(performer_id: params[:performer_id]) if params[:performer_id].present?
        scoped = scoped.where(chore_id: params[:chore_id]) if params[:chore_id].present?
        scoped = scoped.where(chore_type: params[:chore_type]) if params[:chore_type].present?
        performed_from = parse_time(params[:performed_from])
        performed_to = parse_time(params[:performed_to])
        scoped = scoped.where('performed_at >= ?', performed_from) if performed_from
        scoped = scoped.where('performed_at <= ?', performed_to) if performed_to
        return scoped if params[:chore_name].blank?

        keyword = "%#{params[:chore_name]}%"
        scoped.left_joins(:chore).where('chores.name ILIKE ? OR chore_records.custom_chore_name ILIKE ?', keyword, keyword)
      end

      def parse_time(value)
        Time.zone.parse(value)
      rescue ArgumentError, TypeError
        nil
      end

      def create_params
        params.permit(:text, :creator_id)
      end

      def update_params
        params.require(:chore_record).permit(:performer_id, :chore_id, :chore_type, :custom_chore_name, :points, :performed_at)
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
          chore_type: record.chore_type,
          chore_id: record.chore_id,
          custom_chore_name: record.custom_chore_name,
          chore_name: record.display_chore_name,
          performer_id: record.performer_id,
          performer_name: record.performer.name,
          creator_id: record.creator_id,
          points: record.points.to_f,
          performed_at: record.performed_at.iso8601,
          source_text: record.source_text
        }
      end
    end
  end
end
