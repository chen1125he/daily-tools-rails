# daily-tools-rails

## Deployment with Capistrano

1. Fill in your Git repo and server info:
   - `config/deploy.rb` -> `repo_url`
   - `config/deploy/production.rb` -> `server`, `user`
2. Ensure `config/master.key` exists on the server shared path:
   - `#{deploy_to}/shared/config/master.key`
3. First-time server setup:
   - `bundle exec cap production deploy:check`
4. Deploy:
   - `bundle exec cap production deploy`

Common commands:
- `bundle exec cap production puma:status`
- `bundle exec cap production sidekiq:status`
- `bundle exec cap production deploy:rollback`
