# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

default_phone = ENV.fetch("DEFAULT_USER_PHONE", "13800138000")
default_password = ENV.fetch("DEFAULT_USER_PASSWORD", "ChangeMe123!")

User.find_or_initialize_by(phone: default_phone).tap do |user|
  user.name = user.name.presence || "Default User"
  user.status = "active"
  user.password = default_password if user.new_record?
  user.password_confirmation = default_password if user.new_record?
  user.save!
end
