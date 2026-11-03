# frozen_string_literal: true

class MenuPlan < ApplicationRecord
  belongs_to :user

  validates :days, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :start_date, presence: true
end
