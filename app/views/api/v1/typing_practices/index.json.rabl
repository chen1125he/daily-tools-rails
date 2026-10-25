# frozen_string_literal: true

object false

node(:code) { 0 }

child(:data) do
  child @typing_practices => :items do
    extends 'api/v1/typing_practices/base'
  end
  child(:meta) do
    extends 'api/v1/meta/base'
  end
end
