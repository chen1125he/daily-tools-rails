# frozen_string_literal: true

class AddRemovedAtToChoreRecords < ActiveRecord::Migration[8.1]
  def change
    add_column :chore_records, :removed_at, :datetime
  end
end
