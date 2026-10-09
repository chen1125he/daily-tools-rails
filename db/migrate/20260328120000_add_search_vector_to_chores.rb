# frozen_string_literal: true

class AddSearchVectorToChores < ActiveRecord::Migration[8.1]
  def up
    add_column :chores, :search_keywords, :text
    add_column :chores, :search_tokens, :text
    add_column :chores, :search_vector, :tsvector
    add_index :chores, :search_vector, using: :gin

    say_with_time 'backfill chores search_vector' do
      Chore.reset_column_information
      Chore.find_each do |chore|
        chore.rebuild_search_vector!
        chore.update_columns(search_tokens: chore.search_tokens, search_vector: chore.search_vector)
      end
    end
  end

  def down
    remove_index :chores, :search_vector
    remove_column :chores, :search_keywords
    remove_column :chores, :search_vector
    remove_column :chores, :search_tokens
  end
end
