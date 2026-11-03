# frozen_string_literal: true

class CreateMenuPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :menu_plans do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :days, null: false, comment: '规划天数'
      t.date :start_date, null: false, comment: '起始日期'
      t.jsonb :ai_parse_payload, comment: 'AI 生成结果'

      t.timestamps
    end

    add_reference :menus, :menu_plan
    add_column :menus, :rationale, :text, comment: '本餐搭配与营养考虑'
  end
end
