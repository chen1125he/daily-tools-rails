# frozen_string_literal: true

object false

node(:code) { 0 }

child @typing_word => :data do
  extends 'api/v1/typing_words/base'
end
