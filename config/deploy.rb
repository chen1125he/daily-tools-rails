# frozen_string_literal: true

lock '~> 3.20.0'

set :application, 'daily_tools_rails'
set :repo_url, ENV.fetch('CAP_REPO_URL', 'git@github.com:chen1125he/daily-tools-rails.git')
set :deploy_to, "/var/www/#{fetch(:application)}"
set :branch, ENV.fetch('CAP_BRANCH', 'develop')

# Deploy output settings.
set :format, :airbrussh
set :log_level, ENV.fetch('CAP_LOG_LEVEL', 'info').to_sym
set :pty, false

set :rbenv_type, :user
set :rbenv_ruby, '3.3.9'
set :service_unit_env_files, [ '/etc/systemd/system/daily_tools_rails.env' ]

append :linked_files, 'config/master.key', 'config/credentials/production.key'
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'storage', '.bundle'

# Bundler 2+ no longer accepts --deployment as a CLI flag.
set :bundle_config, { deployment: true }
set :bundle_jobs, 1
set :bundle_flags, ''

set :keep_releases, 5

# Puma
set :puma_init_active_record, true
set :puma_role, :app
set :puma_bind, "unix://#{shared_path}/tmp/sockets/puma.sock"
set :puma_service_unit_env_vars, [ "PUMA_BIND=unix://#{fetch(:deploy_to)}/shared/tmp/sockets/puma.sock" ]

# Sidekiq
set :sidekiq_roles, :app
set :sidekiq_processes, 1
set :sidekiq_config_files, [ 'sidekiq.yml' ]
set :sidekiq_service_unit_name, "#{fetch(:application)}_sidekiq_#{fetch(:stage)}"
