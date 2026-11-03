# frozen_string_literal: true

class ReassociateTypingErrorMarksToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :typing_error_marks, :user, null: true, foreign_key: true
    add_column :typing_error_marks, :recent_mistake_count, :integer, null: false, default: 1,
               comment: '近期错误次数'
    change_column_comment :typing_error_marks, :mistake_count, from: '该字出错次数', to: '错误总次数'

    remove_index :typing_error_marks, name: 'index_typing_error_marks_on_practice_and_word'
    remove_reference :typing_error_marks, :typing_practice, foreign_key: true

    add_index :typing_error_marks, %i[user_id typing_word_id],
              unique: true, name: 'index_typing_error_marks_on_user_and_word'
  end
end
