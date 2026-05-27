# frozen_string_literal: true

class RenameChoreRecordUserColumns < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :chore_records, column: :created_by_id if foreign_key_exists?(:chore_records, :users, column: :created_by_id)
    remove_foreign_key :chore_records, column: :performed_by_id if foreign_key_exists?(:chore_records, :users, column: :performed_by_id)

    rename_column :chore_records, :created_by_id, :creator_id if column_exists?(:chore_records, :created_by_id)
    rename_column :chore_records, :performed_by_id, :performer_id if column_exists?(:chore_records, :performed_by_id)

    remove_index :chore_records, name: 'index_chore_records_on_created_by_id' if index_exists?(:chore_records, :creator_id, name: 'index_chore_records_on_created_by_id')
    remove_index :chore_records, name: 'index_chore_records_on_performed_by_id' if index_exists?(:chore_records, :performer_id, name: 'index_chore_records_on_performed_by_id')
    remove_index :chore_records, name: 'index_chore_records_on_performed_by_id_and_performed_at' if index_exists?(:chore_records, %i[performer_id performed_at], name: 'index_chore_records_on_performed_by_id_and_performed_at')

    add_index :chore_records, :creator_id, name: 'index_chore_records_on_creator_id' unless index_exists?(:chore_records, :creator_id, name: 'index_chore_records_on_creator_id')
    add_index :chore_records, :performer_id, name: 'index_chore_records_on_performer_id' unless index_exists?(:chore_records, :performer_id, name: 'index_chore_records_on_performer_id')
    add_index :chore_records, %i[performer_id performed_at], name: 'index_chore_records_on_performer_id_and_performed_at' unless index_exists?(:chore_records, %i[performer_id performed_at], name: 'index_chore_records_on_performer_id_and_performed_at')

    add_foreign_key :chore_records, :users, column: :creator_id unless foreign_key_exists?(:chore_records, :users, column: :creator_id)
    add_foreign_key :chore_records, :users, column: :performer_id unless foreign_key_exists?(:chore_records, :users, column: :performer_id)
  end

  def down
    remove_foreign_key :chore_records, column: :creator_id if foreign_key_exists?(:chore_records, :users, column: :creator_id)
    remove_foreign_key :chore_records, column: :performer_id if foreign_key_exists?(:chore_records, :users, column: :performer_id)

    rename_column :chore_records, :creator_id, :created_by_id if column_exists?(:chore_records, :creator_id)
    rename_column :chore_records, :performer_id, :performed_by_id if column_exists?(:chore_records, :performer_id)

    remove_index :chore_records, name: 'index_chore_records_on_creator_id' if index_exists?(:chore_records, :created_by_id, name: 'index_chore_records_on_creator_id')
    remove_index :chore_records, name: 'index_chore_records_on_performer_id' if index_exists?(:chore_records, :performed_by_id, name: 'index_chore_records_on_performer_id')
    remove_index :chore_records, name: 'index_chore_records_on_performer_id_and_performed_at' if index_exists?(:chore_records, %i[performed_by_id performed_at], name: 'index_chore_records_on_performer_id_and_performed_at')

    add_index :chore_records, :created_by_id, name: 'index_chore_records_on_created_by_id' unless index_exists?(:chore_records, :created_by_id, name: 'index_chore_records_on_created_by_id')
    add_index :chore_records, :performed_by_id, name: 'index_chore_records_on_performed_by_id' unless index_exists?(:chore_records, :performed_by_id, name: 'index_chore_records_on_performed_by_id')
    add_index :chore_records, %i[performed_by_id performed_at], name: 'index_chore_records_on_performed_by_id_and_performed_at' unless index_exists?(:chore_records, %i[performed_by_id performed_at], name: 'index_chore_records_on_performed_by_id_and_performed_at')

    add_foreign_key :chore_records, :users, column: :created_by_id unless foreign_key_exists?(:chore_records, :users, column: :created_by_id)
    add_foreign_key :chore_records, :users, column: :performed_by_id unless foreign_key_exists?(:chore_records, :users, column: :performed_by_id)
  end
end
