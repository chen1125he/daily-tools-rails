# frozen_string_literal: true

object false

node(:code) { 0 }

child @chore_record => :data do
  extends 'api/v1/chore_records/base'
end
