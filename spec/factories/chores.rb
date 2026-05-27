# frozen_string_literal: true

FactoryBot.define do
  factory :chore do
    sequence(:name) { |n| "家务#{n}" }
    active { true }
    description { '家务描述' }
    default_points { 1 }
  end
end
