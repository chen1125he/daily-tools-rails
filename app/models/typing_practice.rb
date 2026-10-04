# frozen_string_literal: true

class TypingPractice < ApplicationRecord
  belongs_to :user
  belongs_to :typing_article

  has_many :typing_error_marks, dependent: :destroy, inverse_of: :typing_practice
  has_many :typing_words, through: :typing_error_marks

  validates :started_at, presence: true
  validates :correct_count, :error_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :duration_ms, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :accuracy, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :cpm, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
