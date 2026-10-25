# frozen_string_literal: true

attributes :id, :typing_practice_id, :typing_word_id, :mistake_count, :created_at, :updated_at

child(typing_word: :typing_word) do
  extends 'api/v1/typing_words/base'
end
