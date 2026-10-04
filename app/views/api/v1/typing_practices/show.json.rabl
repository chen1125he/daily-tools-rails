# frozen_string_literal: true

object false

node(:code) { 0 }

child @typing_practice => :data do
  extends 'api/v1/typing_practices/base'
end
