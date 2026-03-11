# frozen_string_literal: true

server "YOUR_SERVER_IP_OR_DOMAIN", user: "deploy", roles: %w[app db web]

set :branch, "main"
set :rails_env, "production"
