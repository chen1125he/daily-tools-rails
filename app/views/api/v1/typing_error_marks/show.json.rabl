# frozen_string_literal: true

object false

node(:code) { 0 }

child @typing_error_mark => :data do
  extends 'api/v1/typing_error_marks/base'
end
