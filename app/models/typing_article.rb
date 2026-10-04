# frozen_string_literal: true

class TypingArticle < ApplicationRecord
  has_many :typing_practices, dependent: :restrict_with_exception

  validates :title, presence: true
  validates :body, presence: true

  def character_count
    characters.size
  end

  def characters
    self.class.characters_for(body)
  end

  def self.characters_for(text)
    text.to_s.gsub(/[[:space:]]+/, '').each_grapheme_cluster.to_a
  end
end
