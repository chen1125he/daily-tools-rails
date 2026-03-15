# frozen_string_literal: true

server ENV.fetch('CAP_PRODUCTION_SERVER', ''),
       user: ENV.fetch('CAP_PRODUCTION_USER', 'deploy'),
       roles: %w[app db web],
       primary: true

set :stage, :production
set :rails_env, 'production'

# Keep migration on the :db role only.
set :conditionally_migrate, true
set :migration_role, :db

# Ensure remote commands run in production context.
set :default_env, fetch(:default_env, {}).merge(
  'RAILS_ENV' => fetch(:rails_env)
)