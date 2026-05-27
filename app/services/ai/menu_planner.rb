# frozen_string_literal: true

module Ai
  class MenuPlanner
    ParseError = Class.new(StandardError)

    MEAL_TYPES = %w[lunch dinner].freeze
    RECIPES_PER_MEAL = { 'lunch' => 2, 'dinner' => 3 }.freeze
    AVOID_REPEAT_WITHIN_DAYS = 3
    RECENT_MENU_DAYS = 7
    MAX_DAYS = 14

    class << self
      def call(current_user:, days:, start_date: nil, custom_prompt: nil)
        @current_user = current_user
        @model = Setting.ai_menu_planner_model

        @days = begin
          value = Integer(days)
          raise ParseError, 'days 必须大于 0' if value <= 0
          raise ParseError, "days 不能超过 #{MAX_DAYS}" if value > MAX_DAYS

          value
        rescue ArgumentError, TypeError
          raise ParseError, 'days 必须是正整数'
        end

        @start_date = begin
          if start_date.blank?
            Date.current
          else
            Date.parse(start_date.to_s)
          end
        rescue ArgumentError
          raise ParseError, 'start_date 格式不正确，请使用 YYYY-MM-DD'
        end

        @custom_prompt = custom_prompt.to_s.strip.presence

        @recipes = current_user.recipes.where(in_ai_plan: true).includes(recipe_ingredients: :ingredient).order(:id).to_a
        raise ParseError, '请先添加至少 1 道可用于 AI 规划的食谱' if @recipes.empty?

        @recipe_ids = @recipes.map(&:id)
        @recent_menus = current_user.menus
          .includes(menu_recipes: :recipe)
          .where(menu_date: (@start_date - RECENT_MENU_DAYS.days)...@start_date)
          .order(menu_date: :asc, meal_type: :asc)
          .to_a

        ai_result = plan_with_ai
        validate_plan!(ai_result[:plan])
        persist_plan!(ai_result[:plan], ai_parse_payload: ai_result[:ai_parse_payload])
      end

      private

      def plan_with_ai
        end_date = @start_date + (@days - 1)
        repeat_constraint = <<~TEXT.strip
          #{AVOID_REPEAT_WITHIN_DAYS} 天去重：同一 recipe_id 若在日期 D 的任一餐（午餐或晚餐）出现，则日期 D+1、D+2 的所有餐次均不得再出现该 id（与近期菜单合并计算）。
          示例：近期菜单中 2026-05-20 午餐含 recipe_id=3，则 2026-05-21、2026-05-22 不可再选 3，2026-05-23 起可以。
        TEXT
        recipe_catalog = @recipes.map do |recipe|
          main_ingredients = recipe.main_ingredients.map(&:name).join(', ')
          "- recipe_id=#{recipe.id}，#{recipe.title}，主料：#{main_ingredients}"
        end.join("\n")
        recent_menus = if @recent_menus.empty?
          '（无）'
        else
          @recent_menus.map do |menu|
            dishes = menu.recipes.map { |recipe| "recipe_id=#{recipe.id}(#{recipe.title})" }.join(', ')
            "- #{menu.menu_date.iso8601} #{menu.meal_type}: #{dishes}"
          end.join("\n")
        end

        prompt = <<~PROMPT
          你是家庭菜单规划助手。根据食谱库与近期菜单，生成 #{@start_date.iso8601} 至 #{end_date.iso8601} 的餐次菜单。
          只输出 JSON，不要输出任何其它文字。

          ## 规划范围
          - 日期: #{@start_date.iso8601} 起连续 #{@days} 天
          - 餐次: 每天仅 lunch（2 道菜）、dinner（3 道菜）

          ## 硬性约束（必须全部满足，优先级最高）
          1) recipe_id 只能来自下方食谱库，禁止编造。
          2) #{repeat_constraint}
          3) 同一餐内 recipe_ids 不可重复；lunch 恰好 2 个 id，dinner 恰好 3 个 id。

          ## 软性偏好（在去重等硬性约束满足后再考虑）
          - 每天尽量覆盖蛋白质、蔬菜
          - 避免连续多天重油重肉
          - 在合规前提下适当换花样，勿整段复制近期菜单

          ## 食谱库（仅可选用下列 recipe_id）
          #{recipe_catalog}

          ## 近期菜单（#{@start_date.iso8601} 之前 #{RECENT_MENU_DAYS} 天，去重计算须合并计入）
          #{recent_menus}
        PROMPT

        if @custom_prompt.present?
          prompt << <<~PROMPT

          ## 用户额外要求
          在满足上述硬性约束的前提下尽量满足：
          #{@custom_prompt}
          PROMPT
        end

        prompt << <<~PROMPT

          ## 输出 JSON 格式
          根对象字段:
          - days: 数组，长度 #{@days}，按 date 升序；date 从 #{@start_date.iso8601} 起连续 #{@days} 天（YYYY-MM-DD）。
            每天 meals 仅含 lunch、dinner 各一条：
            - meal_type: "lunch" | "dinner"
            - recipe_ids: 整数数组（食谱库 id）；须同时满足「每餐道菜数」与「#{AVOID_REPEAT_WITHIN_DAYS} 天去重」规则
            - rationale: 一句话说明搭配理由
          禁止额外字段与解释性文字。
        PROMPT

        response = AliyunAi.chat(prompt: prompt, model: @model)
        content = response.dig('choices', 0, 'message', 'content').to_s
        raise ParseError, "AI 响应为空: #{response}" if content.blank?

        parsed = begin
          JSON.parse(content)
        rescue JSON::ParserError
          json_fragment = content[/\{.*\}/m]
          raise ParseError, "无法从 AI 响应中提取 JSON: #{content}" if json_fragment.blank?

          JSON.parse(json_fragment)
        end

        raw_days = Array(parsed['days'] || parsed[:days])
        raise ParseError, 'AI 未返回 days' if raw_days.blank?

        plan = {
          days: raw_days.map do |day|
            date = Date.parse(day.fetch('date').to_s)
            meals = Array(day['meals']).map do |meal|
              {
                date: date,
                meal_type: meal.fetch('meal_type').to_s,
                recipe_ids: Array(meal['recipe_ids']).map { |id| Integer(id) }.uniq,
                rationale: meal['rationale'].to_s.strip
              }
            end

            { date: date, meals: meals }
          end
        }

        { plan: plan, ai_parse_payload: response.merge(prompt: prompt) }
      rescue KeyError, ArgumentError, TypeError => e
        raise ParseError, "AI 输出格式不正确: #{e.message}，原文: #{content}"
      end

      def validate_plan!(plan)
        days = plan[:days]
        expected_dates = @days.times.map { |offset| @start_date + offset }

        raise ParseError, "AI 返回天数不正确，期望 #{@days} 天，实际 #{days.size} 天" if days.size != @days
        raise ParseError, 'AI 返回的日期序列不正确' if days.map { |day| day[:date] } != expected_dates

        seen_meals = {}

        days.each do |day|
          day[:meals].each do |meal|
            key = [ day[:date], meal[:meal_type] ]
            raise ParseError, "AI 返回重复餐次: #{day[:date]} #{meal[:meal_type]}" if seen_meals[key]

            seen_meals[key] = true

            unless MEAL_TYPES.include?(meal[:meal_type])
              raise ParseError, "AI 返回无效餐次: #{meal[:meal_type]}"
            end

            expected_count = RECIPES_PER_MEAL.fetch(meal[:meal_type])
            if meal[:recipe_ids].size != expected_count
              raise ParseError, "#{day[:date]} #{meal[:meal_type]} 应安排 #{expected_count} 道菜，实际 #{meal[:recipe_ids].size} 道"
            end

            invalid_ids = meal[:recipe_ids] - @recipe_ids
            raise ParseError, "AI 返回了不存在的 recipe_id: #{invalid_ids.join(', ')}" if invalid_ids.any?
          end

          missing_meals = MEAL_TYPES - day[:meals].map { |meal| meal[:meal_type] }
          raise ParseError, "AI 未规划 #{day[:date]} 的餐次: #{missing_meals.join(', ')}" if missing_meals.any?
        end
      end

      def persist_plan!(plan, ai_parse_payload:)
        Menu.transaction do
          menu_plan = @current_user.menu_plans.create!(
            days: @days,
            start_date: @start_date,
            custom_prompt: @custom_prompt,
            ai_parse_payload: ai_parse_payload
          )

          plan[:days].each do |day|
            day[:meals].each do |meal|
              menu = @current_user.menus.find_or_initialize_by(
                menu_date: day[:date],
                meal_type: meal[:meal_type]
              )
              menu.recipe_ids = meal[:recipe_ids]
              menu.rationale = meal[:rationale]
              menu.menu_plan = menu_plan
              menu.save!
            end
          end
        end
      end
    end
  end
end
