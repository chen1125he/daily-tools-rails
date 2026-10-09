# frozen_string_literal: true

class AddTypedBodyToTypingPractices < ActiveRecord::Migration[8.1]
  def change
    add_column :typing_practices, :typed_body, :text, comment: '实际打出的内容'
  end
end
