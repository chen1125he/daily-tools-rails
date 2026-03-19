# frozen_string_literal: true

module Ai
  class ChoreRecordParser
    ParseError = Class.new(StandardError)

    class << self
      def call(text:, current_user:)
        @current_user = current_user
        @normalized_text = text.to_s.strip
        raise ParseError, 'text 不能为空' if @normalized_text.blank?

        @model = Setting.ai_chore_record_parser_model

        @default_chore_catalog = default_chore_catalog

        @resolved_user_list = User.all.map do |user|
          {
            id: user.id,
            name: current_user.id == user.id ? "#{user.name} (我自己)" : user.name.to_s,
          }
        end

        ai_result = parse_with_ai

        mapped_chore = nil
        if ai_result[:chore_type] == 'catalog'
          mapped_chore = @default_chore_catalog.find { |item| item[:id] == ai_result[:chore_id] }
          raise ParseError, "AI 返回了不存在的 chore_id: #{ai_result[:chore_id]}" unless mapped_chore
        end

        {
          chore_type: ai_result[:chore_type],
          chore_id: mapped_chore&.dig(:id),
          custom_chore_name: ai_result[:custom_chore_name],
          chore_name: mapped_chore&.dig(:name) || ai_result[:custom_chore_name],
          performer_name: @resolved_user_list.find { |item| item[:id] == ai_result[:performer_id] }[:name],
          performer_id: ai_result[:performer_id] || @current_user.id,
          contribution_points: ai_result[:contribution_points] || mapped_chore&.dig(:default_contribution_points) || 1.0,
          performed_at: ai_result[:performed_at] || Time.current,
          ai_parse_payload: ai_result
        }
      end

      private

      def default_chore_catalog
        Chore.active.map do |chore|
          {
            id: chore.id,
            name: chore.name.to_s,
            description: chore.description.to_s,
            default_contribution_points: chore.default_contribution_points&.to_f
          }
        end
      end

      def normalize_catalog(catalog)
        Array(catalog).filter_map do |item|
          id = item[:id] || item['id']
          name = item[:name] || item['name']
          next if id.blank? || name.blank?

          {
            id: id.to_i,
            name: name.to_s,
            description: (item[:description] || item['description']).to_s,
            default_contribution_points: to_optional_float(item[:default_contribution_points] || item['default_contribution_points'])
          }
        end
      end

      def to_optional_float(value)
        return nil if value.blank?

        Float(value)
      rescue ArgumentError, TypeError
        nil
      end

      def parse_with_ai
        prompt = build_prompt
        response = AliyunAi.chat(prompt: prompt, model: @model)

        content = response.dig('choices', 0, 'message', 'content').to_s
        raise ParseError, "AI 响应为空: #{response}" if content.blank?

        parsed = parse_json_content(content)
        chore_type = parsed['chore_type'].presence || (parsed['chore_id'].present? ? 'catalog' : 'custom')
        raise ParseError, "不支持的 chore_type: #{chore_type}" unless ChoreRecord.chore_types.key?(chore_type)

        chore_id = chore_type == 'catalog' ? Integer(parsed.fetch('chore_id')) : nil
        custom_chore_name = chore_type == 'custom' ? parsed['custom_chore_name'].to_s.strip : nil
        raise ParseError, 'custom_chore_name 不能为空' if chore_type == 'custom' && custom_chore_name.blank?

        points = to_optional_decimal(parsed['contribution_points'])
        performer_id = parsed['performer_id'].present? ? Integer(parsed['performer_id']) : @current_user.id
        performed_at = parsed['performed_at'].present? ? Date.parse(parsed['performed_at']) : nil

        {
          chore_type: chore_type,
          chore_id: chore_id,
          custom_chore_name: custom_chore_name,
          contribution_points: points,
          performer_id: performer_id,
          performed_at: performed_at,
          ai_parse_payload: response.merge(prompt: prompt)
        }
      rescue KeyError, ArgumentError, TypeError => e
        raise ParseError, "AI 输出格式不正确: #{e.message}，原文: #{content}"
      end

      def to_optional_decimal(value)
        return nil if value.blank?

        BigDecimal(value.to_s)
      end

      def build_prompt
        <<~PROMPT
          你是家务记录解析助手。请从用户输入中识别以下数据
          1. 对应的家务类型和贡献分数。
          2. 家务完成的日期。
          3. 家务完成的参与者。
          你必须只输出 JSON，不能输出任何额外文本。

          用户输入:
          #{@normalized_text}

          角色信息(JSON):
          #{@resolved_user_list.to_json}

          家务候选列表(JSON):
          #{@default_chore_catalog.to_json}

          今天是 #{Date.today.strftime('%Y-%m-%d')}。

          输出要求:
          1) 输出 JSON 对象，字段严格为:
             - chore_type: String，只能是 "catalog" 或 "custom" 自定义家务类型为 "custom"，默认类型为 "catalog"。
             - custom_chore_name: String，仅在 chore_type="custom" 时返回，必须返回自定义家务名称。
             - chore_id: Integer，仅在 chore_type="catalog" 时返回，必须来自候选列表中的 id
             - contribution_points: Number，必须大于 0, 如果输入里没有明确分数，返回空值(nil)。
             - performer_id: Integer，必须来自角色信息中的 id, 如果输入里没有明确参与者，返回空值(nil)。
             - performed_at: Date，推算出家务完成的日期, 如果用户输入里没有明确日期，返回空值(nil)。
          2) 不允许新增字段，不允许解释。
        PROMPT
      end

      def parse_json_content(content)
        JSON.parse(content)
      rescue JSON::ParserError
        json_fragment = content[/\{.*\}/m]
        raise ParseError, "无法从 AI 响应中提取 JSON: #{content}" if json_fragment.blank?

        JSON.parse(json_fragment)
      end
    end
  end
end
