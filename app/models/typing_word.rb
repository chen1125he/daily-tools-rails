# frozen_string_literal: true

class TypingWord < ApplicationRecord
  has_many :typing_error_marks, dependent: :restrict_with_exception

  validates :character, presence: true, uniqueness: true, length: { is: 1 }
  validates :wubi_code, length: { maximum: 4 }, allow_blank: true

  def self.find_or_create_for!(character:, wubi_code: nil)
    word = find_or_initialize_by(character: character.to_s.strip)
    word.wubi_code = wubi_code if wubi_code.present? && word.wubi_code.blank?
    word.save!
    word
  rescue ActiveRecord::RecordNotUnique
    find_by!(character: character.to_s.strip)
  end
end
