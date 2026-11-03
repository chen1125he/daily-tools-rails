# frozen_string_literal: true

class TypingErrorMark < ApplicationRecord
  belongs_to :user
  belongs_to :typing_word

  validates :typing_word_id, uniqueness: { scope: :user_id }
  validates :mistake_count, numericality: { only_integer: true, greater_than: 0 }
  validates :recent_mistake_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.record!(user:, character:)
    word = TypingWord.find_by!(character: character.to_s.strip)

    retries = 0
    begin
      transaction do
        mark = user.typing_error_marks.lock.find_by(typing_word_id: word.id)
        if mark
          mark.update!(
            mistake_count: mark.mistake_count + 1,
            recent_mistake_count: mark.recent_mistake_count + 1
          )
        else
          mark = user.typing_error_marks.create!(
            typing_word: word,
            mistake_count: 1,
            recent_mistake_count: 1
          )
        end
        mark
      end
    rescue ActiveRecord::RecordNotUnique
      retry if (retries += 1) < 3
      raise
    end
  end
end
