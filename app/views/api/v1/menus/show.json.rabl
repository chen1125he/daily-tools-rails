# frozen_string_literal: true

object false

node(:code) { 0 }

child @menu => :data do
  extends 'api/v1/menus/base'
end
