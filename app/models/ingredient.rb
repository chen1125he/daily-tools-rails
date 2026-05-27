# frozen_string_literal: true

class Ingredient < ApplicationRecord
  KEYWORD_SPLIT = /[\s,，、]+/

  has_many :recipe_ingredients, dependent: :restrict_with_exception
  has_many :recipes, through: :recipe_ingredients

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  # 按展示名或 search_keywords 中的别名查找已有食材（大小写不敏感）；未命中返回 nil。
  def self.find_matching_label(label)
    needle = label.to_s.strip
    return nil if needle.blank?

    needle_down = needle.mb_chars.downcase.to_s

    by_name = where('LOWER(TRIM(name)) = ?', needle_down).first
    return by_name if by_name

    exists_sql = sanitize_sql_array([
      <<~SQL.squish,
        EXISTS (
          SELECT 1
          FROM regexp_split_to_table(
            lower(trim(coalesce(#{table_name}.search_keywords, ''))),
            '[[:space:],，、]+'
          ) AS kw(token)
          WHERE token <> '' AND token = ?
        )
      SQL
      needle_down
    ])
    where(exists_sql).take
  end

  def keyword_tokens
    search_keywords.to_s.split(KEYWORD_SPLIT).map(&:strip).reject(&:blank?)
  end
end
