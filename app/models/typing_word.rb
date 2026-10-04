# frozen_string_literal: true

class TypingWord < ApplicationRecord
  has_many :typing_error_marks, dependent: :restrict_with_exception

  validates :character, presence: true, uniqueness: true, length: { is: 1 }
  validates :wubi_code, length: { maximum: 4 }, allow_blank: true
  validate :wubi_roots_must_be_string_array

  after_commit :enqueue_wubi_lookup, on: :create

  def self.find_or_create_for!(character:, wubi_code: nil, wubi_roots: nil)
    word = find_or_initialize_by(character: character.to_s.strip)
    word.assign_wubi!(wubi_code: wubi_code, wubi_roots: wubi_roots)
    word.save!
    word
  rescue ActiveRecord::RecordNotUnique
    find_by!(character: character.to_s.strip)
  end

  def self.lookup_wubi!(character:)
    char = character.to_s.strip
    word = find_by(character: char)
    return word if word&.wubi_complete?

    result = Ai::WubiCodeLookup.call(character: char)
    find_or_create_for!(
      character: char,
      wubi_code: result[:wubi_code],
      wubi_roots: result[:wubi_roots]
    )
  end

  def wubi_complete?
    wubi_code.present? && wubi_roots.present?
  end

  def assign_wubi!(wubi_code: nil, wubi_roots: nil)
    self.wubi_code = wubi_code if wubi_code.present? && self.wubi_code.blank?
    self.wubi_roots = wubi_roots if wubi_roots.present? && self.wubi_roots.blank?
  end

  def enqueue_wubi_lookup
    return if wubi_complete?

    TypingWordWubiLookupJob.perform_later(id)
  end

  private

  def wubi_roots_must_be_string_array
    return if wubi_roots.nil?

    unless wubi_roots.is_a?(Array) && wubi_roots.all? { |item| item.is_a?(String) && item.present? }
      errors.add(:wubi_roots, '必须是非空字符串数组')
      return
    end

    return if wubi_roots.size <= 4

    errors.add(:wubi_roots, '最多 4 个字根')
  end
end
