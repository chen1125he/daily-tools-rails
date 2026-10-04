# frozen_string_literal: true

attributes :id, :user_id, :typing_article_id, :typed_body, :started_at, :finished_at,
           :duration_ms, :correct_count, :error_count, :accuracy, :cpm,
           :created_at, :updated_at

node(:status) { |practice| practice.status }

child(typing_article: :typing_article) do
  extends 'api/v1/typing_articles/base'
end

child(typing_error_marks: :typing_error_marks) do
  extends 'api/v1/typing_error_marks/base'
end
