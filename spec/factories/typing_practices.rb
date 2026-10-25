# frozen_string_literal: true

FactoryBot.define do
  factory :typing_practice do
    user
    typing_article
    started_at { nil }
    finished_at { nil }
    correct_count { 0 }
    error_count { 0 }
  end
end
