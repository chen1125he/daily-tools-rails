# frozen_string_literal: true

class AddCustomPromptToMenuPlans < ActiveRecord::Migration[8.1]
  def change
    add_column :menu_plans, :custom_prompt, :text, comment: '用户自定义生成要求'
  end
end
