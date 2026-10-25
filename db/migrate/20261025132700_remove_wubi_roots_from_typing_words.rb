# frozen_string_literal: true

class RemoveWubiRootsFromTypingWords < ActiveRecord::Migration[8.1]
  def change
    remove_column :typing_words, :wubi_roots, :jsonb, comment: '五笔字根'
  end
end
