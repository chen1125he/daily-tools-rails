# frozen_string_literal: true

FactoryBot.define do
  factory :typing_article do
    sequence(:title) { |n| "练习文章#{n}" }
    body { '春眠不觉晓处处闻啼鸟' }
  end
end
