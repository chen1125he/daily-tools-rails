lock "~> 3.20.0"

set :application, "daily_tools_rails"
set :repo_url, "git@github.com:YOUR_GITHUB_USERNAME/daily-tools-rails.git"
set :deploy_to, "/var/www/#{fetch(:application)}"

set :rbenv_type, :user
set :rbenv_ruby, "3.3.9"

append :linked_files, "config/master.key"
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "storage"

set :keep_releases, 5

# Puma
set :puma_init_active_record, true
set :puma_role, :app
set :puma_bind, "unix://#{shared_path}/tmp/sockets/puma.sock"

# Sidekiq
set :sidekiq_roles, :app
set :sidekiq_processes, 1
set :sidekiq_config_files, ["sidekiq.yml"]
