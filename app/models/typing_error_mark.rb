# frozen_string_literal: true

class TypingErrorMark < ApplicationRecord
  belongs_to :typing_practice
  belongs_to :typing_word

  validates :typing_word_id, uniqueness: { scope: :typing_practice_id }
  validates :mistake_count, numericality: { only_integer: true, greater_than: 0 }
end
