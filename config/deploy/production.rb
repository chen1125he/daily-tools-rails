# frozen_string_literal: true

# Optional local file for Cap deploy secrets (not committed).
begin
  require 'dotenv'
  Dotenv.load('.env.cap.production')
rescue LoadError
  # dotenv is available in this project, keep deploy config resilient.
end

server ENV.fetch('CAP_PRODUCTION_SERVER', '8.135.39.60'),
       user: ENV.fetch('CAP_PRODUCTION_USER', 'deploy'),
       roles: %w[app db web],
       primary: true

set :stage, :production
set :rails_env, 'production'
set :redis_url, ENV.fetch('CAP_PRODUCTION_REDIS_URL', ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379/0'))
set :database_url, ENV['CAP_PRODUCTION_DATABASE_URL']
set :database_password, ENV['CAP_PRODUCTION_DB_PASSWORD'] || ENV['DAILY_TOOLS_RAILS_DATABASE_PASSWORD']

# Keep migration on the :db role only.
set :conditionally_migrate, true
set :migration_role, :db

# Ensure remote commands (db:migrate, etc.) receive runtime env vars.
runtime_env = {
  'RAILS_ENV' => fetch(:rails_env),
  'REDIS_URL' => fetch(:redis_url),
  'PUMA_BIND' => "unix://#{shared_path}/tmp/sockets/puma.sock"
}
runtime_env['DATABASE_URL'] = fetch(:database_url) if fetch(:database_url, nil)
runtime_env['DAILY_TOOLS_RAILS_DATABASE_PASSWORD'] = fetch(:database_password) if fetch(:database_password, nil)

set :default_env, fetch(:default_env, {}).merge(runtime_env)
