# frozen_string_literal: true

class AddDescriptionToChoreRecords < ActiveRecord::Migration[8.1]
  def change
    add_column :chore_records, :description, :text
  end
end
