# frozen_string_literal: true

class CreateTypingPractice < ActiveRecord::Migration[8.1]
  def change
    create_table :typing_articles do |t|
      t.string :title, null: false, comment: '文章标题'
      t.text :body, null: false, comment: '练习正文'

      t.timestamps
    end

    create_table :typing_words do |t|
      t.string :character, null: false, comment: '单个汉字'
      t.string :wubi_code, comment: '五笔编码'

      t.timestamps
    end

    add_index :typing_words, :character, unique: true

    create_table :typing_practices do |t|
      t.references :user, null: false, foreign_key: true
      t.references :typing_article, null: false, foreign_key: true
      t.datetime :started_at, comment: '开始练习时间'
      t.datetime :finished_at, comment: '结束练习时间'
      t.integer :duration_ms, comment: '实际用时（毫秒）'
      t.integer :correct_count, null: false, default: 0, comment: '正确字数'
      t.integer :error_count, null: false, default: 0, comment: '错误字数'
      t.decimal :accuracy, precision: 5, scale: 2, comment: '正确率（百分比）'
      t.decimal :cpm, precision: 8, scale: 2, comment: '每分钟字数'

      t.timestamps
    end

    add_index :typing_practices, %i[user_id created_at]

    create_table :typing_error_marks do |t|
      t.references :typing_practice, null: false, foreign_key: true
      t.references :typing_word, null: false, foreign_key: true
      t.integer :mistake_count, null: false, default: 1, comment: '该字出错次数'

      t.timestamps
    end

    add_index :typing_error_marks, %i[typing_practice_id typing_word_id],
              unique: true, name: 'index_typing_error_marks_on_practice_and_word'
  end
end
