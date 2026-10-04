# frozen_string_literal: true

class TypingWord < ApplicationRecord
  has_many :typing_error_marks, dependent: :restrict_with_exception

  validates :character, presence: true, uniqueness: true, length: { is: 1 }
  validates :wubi_code, length: { maximum: 4 }, allow_blank: true

  after_commit :enqueue_wubi_lookup, on: :create

  def self.find_or_create_for!(character:, wubi_code: nil)
    word = find_or_initialize_by(character: character.to_s.strip)
    word.wubi_code = wubi_code if wubi_code.present? && word.wubi_code.blank?
    word.save!
    word
  rescue ActiveRecord::RecordNotUnique
    find_by!(character: character.to_s.strip)
  end

  def self.lookup_wubi!(character:)
    char = character.to_s.strip
    word = find_by(character: char)
    return word if word&.wubi_code.present?

    code = Ai::WubiCodeLookup.call(character: char)
    find_or_create_for!(character: char, wubi_code: code)
  end

  private

  def enqueue_wubi_lookup
    return if wubi_code.present?

    TypingWordWubiLookupJob.perform_later(id)
  end
end
