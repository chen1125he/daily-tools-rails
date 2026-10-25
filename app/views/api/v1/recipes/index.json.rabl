# frozen_string_literal: true

object false

node(:code) { 0 }

child(:data) do
  child @recipes => :items do
    extends 'api/v1/recipes/base'
  end
  child(:meta) do
    extends 'api/v1/meta/base'
  end
end
