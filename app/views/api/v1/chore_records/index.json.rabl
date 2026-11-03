# frozen_string_literal: true

object false

node(:code) { 0 }

child(:data) do
  child @chore_records => :items do
    extends 'api/v1/chore_records/base'
  end
  node(:summary) do
    @summary
  end
  child(:meta) do
    extends 'api/v1/meta/base'
  end
end
