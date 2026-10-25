# frozen_string_literal: true

class CreateMenus < ActiveRecord::Migration[8.1]
  def change
    create_table :menus do |t|
      t.references :user, null: false, foreign_key: true
      t.date :menu_date, null: false, comment: '菜单日期'
      t.integer :meal_type, null: false, comment: '餐次：0 早餐 / 1 午餐 / 2 晚餐'

      t.timestamps
    end

    add_index :menus, %i[menu_date meal_type], name: 'index_menus_on_menu_date_and_meal_type'

    create_table :menu_recipes do |t|
      t.references :menu, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: true

      t.timestamps
    end

    add_index :menu_recipes, %i[menu_id recipe_id], unique: true, name: 'index_menu_recipes_on_menu_id_and_recipe_id'
  end
end
