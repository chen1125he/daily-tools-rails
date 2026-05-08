# frozen_string_literal: true

module Ai
  class RecipeParser
    ParseError = Class.new(StandardError)

    class << self
      def call(text:, current_user:)
        @current_user = current_user
        @normalized_text = text.to_s.strip
        raise ParseError, 'text 不能为空' if @normalized_text.blank?

        @model = Setting.ai_recipe_parser_model
        ai_result = parse_with_ai

        validate_parsed_result!(ai_result)

        recipe = Recipe.transaction do
          recipe = @current_user.recipes.create!(
            title: ai_result[:title],
            prep_minutes: ai_result[:prep_minutes],
            cook_minutes: ai_result[:cook_minutes],
            prep_description: ai_result[:prep_description],
            cook_description: ai_result[:cook_description],
            source_text: @normalized_text,
            ai_parse_payload: ai_result[:ai_parse_payload]
          )

          create_recipe_ingredients!(recipe, ai_result[:ingredients])
          recipe
        end

        {
          recipe: recipe,
          ai_parse_payload: ai_result[:ai_parse_payload]
        }
      end

      private

      def parse_with_ai
        prompt = build_prompt
        response = AliyunAi.chat(prompt: prompt, model: @model)

        content = response.dig('choices', 0, 'message', 'content').to_s
        raise ParseError, "AI 响应为空: #{response}" if content.blank?

        parsed = parse_json_content(content)

        {
          title: parsed['title'].to_s.strip,
          prep_minutes: to_optional_integer(parsed['prep_minutes']),
          cook_minutes: to_optional_integer(parsed['cook_minutes']),
          prep_description: parsed['prep_description'],
          cook_description: parsed['cook_description'],
          ingredients: normalize_ingredients(parsed['ingredients']),
          ai_parse_payload: response.merge(prompt: prompt)
        }
      rescue KeyError, ArgumentError, TypeError => e
        raise ParseError, "AI 输出格式不正确: #{e.message}，原文: #{content}"
      end

      def build_prompt
        <<~PROMPT
          你是菜谱整理助手。请根据用户输入的菜谱笔记，提取结构化数据并输出 JSON。
          你必须只输出 JSON，不能输出任何额外文本。

          用户输入:
          #{@normalized_text}

          输出要求:
          1) 输出 JSON 对象，字段严格为:
             - title: String，菜谱标题，不能为空。
             - prep_minutes: Integer，备菜时长（分钟），无法判断时返回 0。
             - cook_minutes: Integer，烹饪时长（分钟），无法判断时返回 0。
             - prep_description: text，备菜步骤（处理食材），用markdown简单整理一下格式。
             - cook_description: text，烹饪步骤，用markdown简单整理一下格式。
             - ingredients: Object，包含 3 个字段:
               - main: String[]，主料名称列表。
               - side: String[]，配料名称列表。
               - condiment: String[]，调料名称列表。
          2) ingredients 下每个列表只保留食材名称，不要包含数量、单位、做法。
          3) 不允许新增字段，不允许解释。
        PROMPT
      end

      def validate_parsed_result!(result)
        raise ParseError, 'AI 未提取出菜谱标题' if result[:title].blank?
        raise ParseError, 'AI 未提取出备菜步骤' if result[:prep_description].blank?
        raise ParseError, 'AI 未提取出烹饪步骤' if result[:cook_description].blank?
      end

      def create_recipe_ingredients!(recipe, ingredients)
        ingredients.each do |role, names|
          names.each do |raw_name|
            name = raw_name.to_s.strip
            next if name.blank?

            ingredient = Ingredient.find_matching_label(name) || Ingredient.find_or_create_by!(name: name)
            recipe.recipe_ingredients.find_or_create_by!(ingredient: ingredient, role: role)
          end
        end
      end

      def format_steps(steps)
        return nil if steps.blank?

        steps.each_with_index.map { |step, idx| "#{idx + 1}. #{step}" }.join("\n")
      end

      def to_optional_integer(value)
        return nil if value.nil?

        text = value.to_s.strip
        return nil if text.blank?

        Integer(text)
      end

      def to_clean_array(value)
        Array(value).map { |item| item.to_s.strip }.reject(&:blank?)
      end

      def normalize_ingredients(ingredients)
        source = ingredients.is_a?(Hash) ? ingredients : {}

        {
          main: to_clean_array(source['main'] || source[:main]),
          side: to_clean_array(source['side'] || source[:side]),
          condiment: to_clean_array(source['condiment'] || source[:condiment])
        }
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
