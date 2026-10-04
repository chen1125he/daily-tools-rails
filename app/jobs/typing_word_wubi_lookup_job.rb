# frozen_string_literal: true

class TypingWordWubiLookupJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  def perform(typing_word_id)
    word = TypingWord.find(typing_word_id)
    return if word.wubi_code.present?

    code = Ai::WubiCodeLookup.call(character: word.character)
    word.update!(wubi_code: code) if word.wubi_code.blank?
  end
end
