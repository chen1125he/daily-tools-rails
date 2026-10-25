# frozen_string_literal: true

object false

node(:code) { 0 }

child @ingredient => :data do
  extends 'api/v1/ingredients/base'
end
