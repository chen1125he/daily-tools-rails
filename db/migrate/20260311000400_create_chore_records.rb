# frozen_string_literal: true

class CreateChoreRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :chore_records do |t|
      t.references :performed_by, null: false, foreign_key: { to_table: :users }
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :chore, null: false, foreign_key: true
      t.decimal :contribution_points, precision: 5, scale: 2, null: false
      t.datetime :performed_at, null: false
      t.text :source_text
      t.jsonb :ai_parse_payload

      t.timestamps
    end

    add_index :chore_records, :performed_at
    add_index :chore_records, %i[performed_by_id performed_at]
  end
end
