# frozen_string_literal: true

class AddCustomChoreModeToChoreRecords < ActiveRecord::Migration[8.1]
  def change
    add_column :chore_records, :chore_type, :string, null: false, default: 'catalog' unless column_exists?(:chore_records, :chore_type)
    add_column :chore_records, :custom_chore_name, :string unless column_exists?(:chore_records, :custom_chore_name)
    change_column_null :chore_records, :chore_id, true

    add_index :chore_records, :chore_type unless index_exists?(:chore_records, :chore_type)
  end
end
