# frozen_string_literal: true

class CreateChores < ActiveRecord::Migration[8.0]
  def change
    create_table :chores do |t|
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.text :description, comment: '家务描述'
      t.decimal :default_contribution_points, precision: 5, scale: 2, default: 1, comment: '默认贡献积分'

      t.timestamps
    end

    add_index :chores, 'lower(name)', unique: true, name: 'index_chores_on_lower_name'
  end
end
