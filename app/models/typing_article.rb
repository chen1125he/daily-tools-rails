# frozen_string_literal: true

class TypingArticle < ApplicationRecord
  has_many :typing_practices, dependent: :restrict_with_exception

  validates :title, presence: true
  validates :body, presence: true
end
