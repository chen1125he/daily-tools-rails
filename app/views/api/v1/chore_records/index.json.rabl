# frozen_string_literal: true

object false

child @chore_records => :data do
  extends 'api/v1/chore_records/base'
end

child(:meta) do
  extends 'api/v1/meta/base'
end
