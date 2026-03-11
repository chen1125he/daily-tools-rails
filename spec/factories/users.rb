# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:phone) { |n| "1380000#{format('%04d', n)}" }
    sequence(:name) { |n| "User#{n}" }
    password { "Password123" }
    password_confirmation { "Password123" }
    status { "active" }
  end
end
