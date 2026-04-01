# frozen_string_literal: true

module Api
  module V1
    class ChoreRecordsController < ApplicationController
      before_action :set_chore_record, only: %i[show update destroy]

      def index
        @chore_records = ChoreRecord.present.preload(:chore, :performer, :creator)

        filter_by_performer_id
        filter_by_chore_id
        filter_by_performed_at

        @summary = @chore_records.group(:performer_id).sum(:points)
        @summary = @summary.map do |performer_id, points|
          {
            performer_id: performer_id,
            performer_name: User.find(performer_id).name,
            points: points
          }
        end

        @chore_records = @chore_records.order(performed_at: :desc, id: :desc)

        @pagy, @chore_records = pagy(@chore_records)
      end

      def show
        render_api_success(record_payload(@chore_record))
      end

      def parse_from_text
        params.permit!
        parse_payload = Ai::ChoreRecordParser.call(text: params[:text], current_user: current_user)

        @chore_record = ChoreRecord.create!(
          chore_type: parse_payload[:chore_type],
          chore_id: parse_payload[:chore_id],
          custom_chore_name: parse_payload[:custom_chore_name],
          description: params[:text],
          points: parse_payload[:points],
          performer_id: parse_payload[:performer_id],
          performed_at: parse_payload[:performed_at],
          source_text: params[:text],
          creator_id: current_user.id,
          ai_parse_payload: parse_payload[:ai_parse_payload]
        )

        render :show, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render_validation_error(e.record)
      rescue Ai::ChoreRecordParser::ParseError => e
        render json: { error: { code: 'CHORE_RECORD_PARSE_FAILED', message: e.message } },
               status: :unprocessable_entity
      end

      def create
        record = ChoreRecord.new(manual_create_params)
        record.creator_id = current_user.id
        record.chore_type = 'catalog' if record.chore_type.blank?
        normalize_chore_record_for_create!(record)
        record.save!
        @chore_record = ChoreRecord.includes(:chore, :performer, :creator).find(record.id)
        render :show, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render_validation_error(e.record)
      rescue ActionController::ParameterMissing => e
        render json: { error: { code: 'INVALID_PARAMS', message: e.message } }, status: :bad_request
      end

      def update
        return render_validation_error(@chore_record) unless @chore_record.update(update_params)

        render :show
      end

      def destroy
        @chore_record.remove

        render_api_success(record_payload(@chore_record))
      end

      private

      def set_chore_record
        @chore_record = ChoreRecord.present.includes(:chore, :performer, :creator).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_not_found('CHORE_RECORD_NOT_FOUND', '家务记录不存在')
      end

      def filter_by_performer_id
        return unless params[:performer_id].present?

        @chore_records = @chore_records.where(performer_id: params[:performer_id])
      end

      def filter_by_chore_id
        return unless params[:chore_id].present?

        @chore_records = @chore_records.where(chore_id: params[:chore_id])
      end

      def filter_by_performed_at
        return unless params[:performed_at_from].present? && params[:performed_at_to].present?

        performed_at_from = parse_time(params[:performed_at_from])
        performed_at_to = parse_time(params[:performed_at_to])
        return unless performed_at_from && performed_at_to

        @chore_records = @chore_records.where(performed_at: performed_at_from..performed_at_to)
      end

      def parse_time(value)
        Time.zone.parse(value)
      rescue ArgumentError, TypeError
        nil
      end

      def manual_create_params
        params.require(:chore_record).permit(
          :chore_type, :chore_id, :custom_chore_name, :description, :points, :performer_id, :performed_at, :source_text
        )
      end

      def normalize_chore_record_for_create!(record)
        if record.custom?
          record.chore_id = nil
        else
          record.custom_chore_name = nil
        end
      end

      def update_params
        params.require(:chore_record).permit(
          :performer_id, :chore_id, :chore_type, :custom_chore_name, :description, :points, :performed_at
        )
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
          description: record.description,
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
