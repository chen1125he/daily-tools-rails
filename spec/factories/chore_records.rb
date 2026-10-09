# frozen_string_literal: true

FactoryBot.define do
  factory :chore_record do
    association :performer, factory: :user
    association :creator, factory: :user
    association :chore
    points { 1.5 }
    performed_at { Time.current }
    source_text { '我做饭 1.5 小时' }
    ai_parse_payload { { strategy: 'rule_based' } }
  end
end
