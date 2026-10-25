# frozen_string_literal: true

class AddWubiRootsToTypingWords < ActiveRecord::Migration[8.1]
  def change
    add_column :typing_words, :wubi_roots, :jsonb, comment: '五笔字根'
  end
end
