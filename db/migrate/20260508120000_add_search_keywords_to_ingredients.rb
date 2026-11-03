# frozen_string_literal: true

class AddSearchKeywordsToIngredients < ActiveRecord::Migration[8.1]
  def change
    add_column :ingredients, :search_keywords, :text, comment: '别名/检索词，空格或中英文逗号分隔，与 name 一起用于匹配是否已有该食材'
  end
end
