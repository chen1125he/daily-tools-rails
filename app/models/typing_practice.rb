# frozen_string_literal: true

class TypingPractice < ApplicationRecord
  belongs_to :user
  belongs_to :typing_article

  has_many :typing_error_marks, dependent: :destroy, inverse_of: :typing_practice
  has_many :typing_words, through: :typing_error_marks

  validates :correct_count, :error_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :duration_ms, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :accuracy, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :cpm, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  def pending?
    started_at.blank? && finished_at.blank?
  end

  def in_progress?
    started_at.present? && finished_at.blank?
  end

  def completed?
    finished_at.present?
  end

  def status
    return 'completed' if completed?
    return 'in_progress' if in_progress?

    'pending'
  end

  def start!(at: Time.current)
    if completed?
      errors.add(:base, '练习已结束')
      raise ActiveRecord::RecordInvalid, self
    end
    if started_at.present?
      errors.add(:base, '练习已开始')
      raise ActiveRecord::RecordInvalid, self
    end

    update!(started_at: at)
  end

  def complete!(typed_body:)
    if completed?
      errors.add(:base, '练习已结束')
      raise ActiveRecord::RecordInvalid, self
    end
    if started_at.blank?
      errors.add(:base, '练习尚未开始')
      raise ActiveRecord::RecordInvalid, self
    end

    self.typed_body = typed_body
    if typed_body.blank?
      errors.add(:typed_body, '不能为空')
      raise ActiveRecord::RecordInvalid, self
    end

    target = typing_article.characters
    typed = TypingArticle.characters_for(typed_body)
    overlap = [ target.size, typed.size ].min
    matched = overlap.times.count { |index| target[index] == typed[index] }

    self.finished_at = Time.current
    self.correct_count = matched
    self.error_count = (overlap - matched) + (target.size - typed.size).abs
    self.duration_ms = [ ((finished_at - started_at) * 1000).round, 0 ].max
    self.accuracy = target.empty? ? 0 : ((correct_count.to_d * 100) / target.size).round(2)
    minutes = duration_ms.to_f / 60_000
    self.cpm = minutes.positive? ? (correct_count / minutes).round(2) : 0

    save!
  end
end
