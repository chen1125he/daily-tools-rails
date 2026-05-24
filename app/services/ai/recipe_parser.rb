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
               - main: Object[]，主料列表。
               - side: Object[]，配料列表。
               - condiment: Object[]，调料列表。
               每个元素为 Object，且严格只有两键:
               - name: String，仅食材名称，不含数量、单位、做法（如「盐」「五花肉」）。
               - amount: String，该食材在本菜谱中的用量原文，保留数字与单位/器皿说法（如「一勺」「100克」「适量」）；笔记未写则返回空字符串。
          2) 不允许新增字段，不允许解释。
        PROMPT
      end

      def validate_parsed_result!(result)
        raise ParseError, 'AI 未提取出菜谱标题' if result[:title].blank?
        raise ParseError, 'AI 未提取出备菜步骤' if result[:prep_description].blank?
        raise ParseError, 'AI 未提取出烹饪步骤' if result[:cook_description].blank?
      end

      def create_recipe_ingredients!(recipe, ingredients)
        ingredients.each do |role, entries|
          entries.each do |entry|
            name = entry.fetch(:name).to_s.strip
            next if name.blank?

            amount = entry[:amount]
            ingredient = Ingredient.find_matching_label(name) || Ingredient.find_or_create_by!(name: name)
            record = recipe.recipe_ingredients.find_or_initialize_by(ingredient: ingredient, role: role)
            record.amount = amount
            record.save!
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

      def normalize_ingredients(ingredients)
        source = ingredients.is_a?(Hash) ? ingredients : {}

        {
          main: normalize_ingredient_entries(source['main'] || source[:main]),
          side: normalize_ingredient_entries(source['side'] || source[:side]),
          condiment: normalize_ingredient_entries(source['condiment'] || source[:condiment])
        }
      end

      def normalize_ingredient_entries(value)
        Array(value).filter_map do |item|
          name, amount = normalize_ingredient_entry(item)
          next if name.blank?

          { name: name, amount: amount }
        end
      end

      def normalize_ingredient_entry(item)
        case item
        when Hash
          name = (item['name'] || item[:name]).to_s.strip
          raw_amount = item['amount'] || item[:amount]
          amount = raw_amount.nil? ? nil : raw_amount.to_s.strip.presence
        else
          name = item.to_s.strip
          amount = nil
        end
        [ name, amount ]
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
