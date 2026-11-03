# frozen_string_literal: true

class RemoveIndexOnChoreTypeFromChoreRecords < ActiveRecord::Migration[8.1]
  def up
    remove_index :chore_records, :chore_type if index_exists?(:chore_records, :chore_type)
  end

  def down
    add_index :chore_records, :chore_type unless index_exists?(:chore_records, :chore_type)
  end
end
