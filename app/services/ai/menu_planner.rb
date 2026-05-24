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
      def call(current_user:, days:, start_date: nil)
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
        recipe_catalog = @recipes.map do |recipe|
          {
            id: recipe.id,
            title: recipe.title,
            main_ingredients: recipe.recipe_ingredients.select(&:main?).filter_map { |r| r.ingredient&.name.to_s.strip.presence },
            side_ingredients: recipe.recipe_ingredients.select(&:side?).filter_map { |r| r.ingredient&.name.to_s.strip.presence },
            total_minutes: [ recipe.prep_minutes, recipe.cook_minutes ].compact.sum,
            nutrition: recipe.nutrition.presence
          }
        end
        recent_menus = @recent_menus.map do |menu|
          {
            date: menu.menu_date.iso8601,
            meal_type: menu.meal_type,
            recipe_ids: menu.menu_recipes.map(&:recipe_id),
            titles: menu.recipes.map(&:title)
          }
        end

        prompt = <<~PROMPT
          你是家庭菜单规划助手。请根据用户的食谱库和最近菜单，生成未来 #{@days} 天的餐次菜单。
          你必须只输出 JSON，不能输出任何额外文本。

          规划日期: #{@start_date.iso8601} 至 #{end_date.iso8601}
          需要规划的餐次: lunch, dinner

          约束:
          - lunch 安排 2 道菜，dinner 安排 3 道菜
          - #{AVOID_REPEAT_WITHIN_DAYS} 天内尽量不重复同一道菜
          - 只能从食谱库中选择 recipe_id，不能编造
          - 考虑营养平衡：每天尽量覆盖蛋白质、蔬菜、主食；避免连续多天重油重肉
          - 参考最近菜单，避免简单复制，适当换花样

          食谱库(JSON):
          #{recipe_catalog.to_json}

          最近 #{RECENT_MENU_DAYS} 天菜单(JSON):
          #{recent_menus.to_json}

          输出要求:
          1) 输出 JSON 对象，字段严格为:
             - days: Object[]，长度必须为 #{@days}，按日期升序。
               每个元素为:
               - date: String，ISO8601 日期 YYYY-MM-DD，从 #{@start_date.iso8601} 起连续 #{@days} 天。
               - meals: Object[]，仅包含 lunch 和 dinner。
                 每个元素为:
                 - meal_type: String，只能是 "lunch" | "dinner"。
                 - recipe_ids: Integer[]，来自食谱库，lunch 必须 2 个，dinner 必须 3 个，同一餐内不可重复。
                 - rationale: String，简短说明本餐搭配与营养考虑（1 句话）。
          2) 不允许新增字段，不允许解释。
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
