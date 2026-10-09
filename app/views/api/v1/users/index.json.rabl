# frozen_string_literal: true

object false

node(:code) { 0 }

child @users => :data do
  attributes :id, :name
end
