require 'bundler/setup'
Bundler.require

STDOUT.sync = true

DB = Sequel.connect(ENV['DATABASE_URL'] || "postgres://localhost/heroku-log-drain",
  :max_connections => ENV['MAX_DB_CONNECTIONS'] ? ENV['MAX_DB_CONNECTIONS'].to_i : 4
)
DB.extension :pg_hstore