# frozen_string_literal: true

class AddInAiPlanToRecipes < ActiveRecord::Migration[8.1]
  def change
    add_column :recipes, :in_ai_plan, :boolean, null: false, default: true, comment: 'AI 规划菜单时是否使用此菜谱'
  end
end
