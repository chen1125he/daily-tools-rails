# frozen_string_literal: true

module Ai
  class WubiCodeLookup
    ParseError = Class.new(StandardError)
    WUBI_CODE_PATTERN = /\A[a-z]{1,4}\z/

    class << self
      def call(character:)
        char = character.to_s.strip
        raise ParseError, 'character 不能为空' if char.blank?
        raise ParseError, 'character 必须是单个汉字' unless char.length == 1 && char.match?(/\p{Han}/)

        model = Setting.ai_wubi_lookup_model
        prompt = build_prompt(char)
        response = AliyunAi.chat(prompt: prompt, model: model)
        content = response.dig('choices', 0, 'message', 'content').to_s
        raise ParseError, "AI 响应为空: #{response}" if content.blank?

        parsed = parse_json_content(content)
        code = parsed['wubi_code'].to_s.strip.downcase
        raise ParseError, "AI 未返回有效五笔编码: #{content}" unless code.match?(WUBI_CODE_PATTERN)

        code
      end

      private

      def build_prompt(character)
        <<~PROMPT
          你是五笔输入法编码助手。请给出汉字「#{character}」的 86 版五笔全码。
          你必须只输出 JSON，不能输出任何额外文本。

          输出要求:
          1) 输出 JSON 对象，字段严格为:
             - character: String，必须等于「#{character}」
             - wubi_code: String，86 版五笔全码，仅小写英文字母，长度 1 到 4
          2) 不允许新增字段，不允许解释，不要输出简码以外的说明。
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
