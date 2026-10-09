# frozen_string_literal: true

class CreateRecipeFeatures < ActiveRecord::Migration[8.0]
  def change
    create_table :recipes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false, comment: '标题'
      t.text :prep_description, comment: '备菜步骤描述'
      t.text :cook_description, comment: '烹饪步骤描述'
      t.text :nutrition, comment: '营养成分'

      t.integer :prep_minutes, comment: '准备时间（分钟）'
      t.integer :cook_minutes, comment: '烹饪时间（分钟）'

      t.text :source_text, comment: '原始文本'
      t.jsonb :ai_parse_payload, comment: 'AI 解析结果'

      t.timestamps
    end

    create_table :ingredients do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :ingredients, :name, unique: true, name: 'index_ingredients_on_name'

    create_table :recipe_ingredients do |t|
      t.references :recipe, null: false, foreign_key: true
      t.references :ingredient, null: false, foreign_key: true
      t.integer :role, null: false
      t.string :amount, comment: '用量/份'

      t.timestamps
    end
  end
end
