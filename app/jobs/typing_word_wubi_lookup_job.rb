# frozen_string_literal: true

class TypingWordWubiLookupJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  def perform(typing_word_id)
    word = TypingWord.find(typing_word_id)
    return if word.wubi_complete?

    result = Ai::WubiCodeLookup.call(character: word.character)
    word.assign_wubi!(wubi_code: result[:wubi_code], wubi_roots: result[:wubi_roots])
    word.save! if word.changed?
  end
end
