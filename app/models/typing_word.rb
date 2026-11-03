# frozen_string_literal: true

class TypingWord < ApplicationRecord
  has_many :typing_error_marks, dependent: :restrict_with_exception

  validates :character, presence: true, uniqueness: true, length: { is: 1 }
  validates :wubi_code, length: { maximum: 4 }, allow_blank: true
end
