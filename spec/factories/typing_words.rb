# frozen_string_literal: true

FactoryBot.define do
  factory :typing_word do
    sequence(:character) { |n| (0x4E00 + n).chr(Encoding::UTF_8) }
    wubi_code { 'aaaa' }
    wubi_roots { %w[工 工 工 工] }
  end
end
