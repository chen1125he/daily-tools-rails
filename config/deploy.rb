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

# Bundler 2+ 不再接受 CLI 的 --deployment，改用 bundle config。
# --full-index：跳过 Compact Index，避免国内镜像卡在 Fetching source index；
# bundle_jobs=1：2G 小机器上并行编译 gem 容易 OOM。
# 服务器 shared/.bundle 建议镜像到清华/阿里云，勿用已坏证书的 gems.ruby-china.com。
set :bundle_config, { deployment: true }
set :bundle_jobs, 1
set :bundle_flags, '--full-index --quiet'

set :keep_releases, 5

# Puma
set :puma_init_active_record, true
set :puma_role, :app
set :puma_bind, "unix://#{shared_path}/tmp/sockets/puma.sock"
set :puma_service_unit_env_vars, [ "PUMA_BIND=unix://#{fetch(:deploy_to)}/shared/tmp/sockets/puma.sock" ]

# Sidekiq（生产 Redis 需 >= 6.2，Sidekiq 7 硬性要求）
set :sidekiq_roles, :app
set :sidekiq_processes, 1
set :sidekiq_config_files, [ 'sidekiq.yml' ]
set :sidekiq_service_unit_name, "#{fetch(:application)}_sidekiq_#{fetch(:stage)}"

# 2G 无 swap：bundle install 前先停 Puma/Sidekiq，避免和拉索引/编 native gem 抢内存把机器打挂。
# 部署期间会短暂不可用，流程末尾 puma:restart / sidekiq:start 会再拉起。
before 'bundler:install', 'sidekiq:stop'
before 'bundler:install', 'puma:stop'
