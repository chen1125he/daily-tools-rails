# frozen_string_literal: true

module Ai
  class ChoreRecordParser
    ParseError = Class.new(StandardError)

    class << self
      def call(text:, current_user:)
        normalized_text = text.to_s.strip
        raise ParseError, 'text 不能为空' if normalized_text.blank?

        {
          chore_name: extract_chore_name(normalized_text),
          performed_by_name: extract_performed_by_name(normalized_text, current_user),
          contribution_points: extract_contribution_points(normalized_text),
          performed_at: extract_performed_at(normalized_text),
          confidence: 0.6,
          raw: { strategy: 'rule_based', text: normalized_text }
        }
      end

      private

      def extract_chore_name(text)
        direct_match = text.match(/(做饭|洗碗|拖地|扫地|收拾|整理|洗衣服|倒垃圾)/)
        return direct_match[1] if direct_match

        verb_object_match = text.match(/(?:我|他|她|我们|一起)?(?:在)?(做|洗|拖|扫|整理|收拾)([^\s，。,.]{1,10})/)
        return "#{verb_object_match[1]}#{verb_object_match[2]}" if verb_object_match

        duration_match = text.match(/([^\s，。,.]{1,12})\s*\d+(?:\.\d+)?\s*(?:小时|h|点)/)
        return duration_match[1] if duration_match

        raise ParseError, '无法识别家务名称'
      end

      def extract_performed_by_name(text, current_user)
        return current_user.name if text.include?('我')

        match = text.match(/(?:由|给|帮)?([^\s，。,.]{1,20})(?:做的|完成|干的)/)
        return match[1] if match&.[](1).present?

        current_user.name
      end

      def extract_contribution_points(text)
        match = text.match(/(\d+(?:\.\d+)?)\s*(?:小时|h|点)/)
        return match[1].to_d if match

        1.0.to_d
      end

      def extract_performed_at(text)
        return Time.current if text.include?('今天')
        return 1.day.ago if text.include?('昨天') || text.include?('昨晚')

        Time.current
      end
    end
  end
end
