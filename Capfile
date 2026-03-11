# frozen_string_literal: true

require "capistrano/setup"
require "capistrano/deploy"

require "capistrano/rbenv"
require "capistrano/bundler"
require "capistrano/rails/assets"
require "capistrano/rails/migrations"
require "capistrano/sidekiq"
require "capistrano/puma"

install_plugin Capistrano::Puma
install_plugin Capistrano::Puma::Systemd
install_plugin Capistrano::Sidekiq
install_plugin Capistrano::Sidekiq::Systemd

Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }
