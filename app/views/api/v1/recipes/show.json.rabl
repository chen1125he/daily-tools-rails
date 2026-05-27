# frozen_string_literal: true

object false

node(:code) { 0 }

child @recipe => :data do
  extends 'api/v1/recipes/base'
end
