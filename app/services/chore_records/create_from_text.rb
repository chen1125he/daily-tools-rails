# frozen_string_literal: true

module ChoreRecords
  class CreateFromText
    Result = Struct.new(:success?, :record, :meta, :error_code, :error_message, :errors, keyword_init: true)

    class << self
      def call(text:, created_by_id:, current_user:)
        parsed = Ai::ChoreRecordParser.call(text: text, current_user: current_user)
        chore = Chore.find_or_create_by!(name: parsed[:chore_name]) do |new_chore|
          new_chore.active = true
        end

        performed_by = resolve_user(name: parsed[:performed_by_name], fallback_user: current_user)
        return mapping_error('人员未识别') unless performed_by

        record = ChoreRecord.new(
          performed_by: performed_by,
          created_by_id: created_by_id,
          chore: chore,
          contribution_points: parsed[:contribution_points],
          performed_at: parsed[:performed_at],
          source_text: text,
          ai_parse_payload: parsed
        )

        if record.save
          Result.new(success?: true, record: record, meta: build_meta(parsed))
        else
          Result.new(
            success?: false,
            error_code: 'CHORE_RECORD_VALIDATION_FAILED',
            error_message: record.errors.full_messages.to_sentence,
            errors: record.errors.to_hash
          )
        end
      rescue Ai::ChoreRecordParser::ParseError => e
        Result.new(success?: false, error_code: 'CHORE_RECORD_PARSE_FAILED', error_message: e.message)
      rescue ActiveRecord::RecordInvalid => e
        Result.new(success?: false, error_code: 'CHORE_RECORD_VALIDATION_FAILED', error_message: e.record.errors.full_messages.to_sentence, errors: e.record.errors.to_hash)
      end

      private

      def resolve_user(name:, fallback_user:)
        return fallback_user if name.blank?

        User.active.find_by(name: name) || fallback_user
      end

      def mapping_error(message)
        Result.new(success?: false, error_code: 'CHORE_RECORD_MAPPING_FAILED', error_message: message)
      end

      def build_meta(parsed)
        {
          ai_confidence: parsed[:confidence].to_f,
          needs_review: parsed[:confidence].to_f < 0.8
        }
      end
    end
  end
end
