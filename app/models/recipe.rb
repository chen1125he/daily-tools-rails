# frozen_string_literal: true

class Recipe < ApplicationRecord
  ROLE_LABELS = {
    'main' => '主料',
    'side' => '辅料',
    'condiment' => '调料'
  }.freeze

  belongs_to :user

  has_many :recipe_ingredients, -> { order(:role, :id) }, dependent: :destroy, inverse_of: :recipe
  has_many :ingredients, through: :recipe_ingredients
  has_many :menu_recipes, dependent: :destroy
  has_many :menus, through: :menu_recipes

  accepts_nested_attributes_for :recipe_ingredients, allow_destroy: true

  validates :title, presence: true
  validates :prep_minutes, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :cook_minutes, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  def full_recipe_text
    lines = []
    lines << '# 食材'
    lines << ''
    lines << render_ingredient_line('main')
    lines << render_ingredient_line('side')
    lines << render_ingredient_line('condiment')
    lines << ''
    lines << '# 时长'
    lines << ''
    lines << "- 备菜时长: #{prep_minutes.present? ? "#{prep_minutes} 分钟" : '未知'}"
    lines << "- 烹饪时长: #{cook_minutes.present? ? "#{cook_minutes} 分钟" : '未知'}"
    lines << ''
    lines << '# 备菜步骤'
    lines << ''
    lines << (prep_description.presence || '暂无')
    lines << ''
    lines << '# 烹饪步骤'
    lines << ''
    lines << (cook_description.presence || '暂无')
    lines << ''
    # lines << '## 主要营养成分'
    # lines << ''
    # lines << (nutrition.presence || '暂无')
    lines.join("\n")
  end

  private

  def render_ingredient_line(role)
    names = ingredients_by_role(role)
    return "- #{ROLE_LABELS.fetch(role)}: 未提供" if names.blank?

    "- #{ROLE_LABELS.fetch(role)}: #{names.join('、')}"
  end

  def ingredients_by_role(role)
    recipe_ingredients
      .where(role: role)
      .includes(:ingredient)
      .map { |record| record.ingredient&.name.to_s.strip }
      .reject(&:blank?)
  end
end
