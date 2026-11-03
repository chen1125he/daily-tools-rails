# frozen_string_literal: true

object false

node(:code) { 0 }

child @typing_error_marks => :data do
  attributes :id, :mistake_count, :recent_mistake_count

  node(:character) { |mark| mark.typing_word.character }
end
