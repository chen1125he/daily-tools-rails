# frozen_string_literal: true

class TypingErrorMark < ApplicationRecord
  belongs_to :typing_practice, inverse_of: :typing_error_marks
  belongs_to :typing_word

  validates :typing_word_id, uniqueness: { scope: :typing_practice_id }
  validates :mistake_count, numericality: { only_integer: true, greater_than: 0 }

  def self.record!(typing_practice:, character:)
    word = TypingWord.find_or_create_for!(character: character)

    retries = 0
    begin
      transaction do
        mark = typing_practice.typing_error_marks.lock.find_by(typing_word_id: word.id)
        if mark
          mark.increment!(:mistake_count)
        else
          mark = typing_practice.typing_error_marks.create!(typing_word: word)
        end
        mark
      end
    rescue ActiveRecord::RecordNotUnique
      retry if (retries += 1) < 3
      raise
    end
  end
end
