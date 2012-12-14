require 'bundler/setup'
Bundler.require
$LOAD_PATH << File.expand_path('../lib', __FILE__)
require 'parsley'

STDOUT.sync = true

DB = Sequel.connect(ENV['DATABASE_URL'] || "postgres://localhost/clorox",
  :max_connections => ENV['MAX_DB_CONNECTIONS'] ? ENV['MAX_DB_CONNECTIONS'].to_i : 4
)
DB.extension :pg_hstore

class CloroxServer < Goliath::API

  def response(env)

    if(env[Goliath::Request::REQUEST_METHOD] == 'POST')
      parsley = Parsley.parser(:heroku).new(env[Goliath::Request::RACK_INPUT].read)
      parsley.events do |event|
        DB[:events].insert(
          Parsley::SyslogKeys,
          Parsley::SyslogKeys.collect { |k| event[k] }
        )
        STDOUT.puts(event[:emitted_at].to_s + " -- " + event[:message])
      end
    end

    [200, {}, "ok"]
  end
end

__END__

CREATE EXTENSION hstore;

CREATE table events (
  id SERIAL8 PRIMARY KEY,
  emitted_at TIMESTAMP WITH TIME ZONE,
  received_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  priority INTEGER,
  syslog_version INTEGER,
  hostname CHARACTER(255),
  appname CHARACTER(255),
  proc_id CHARACTER(255),
  msg_id CHARACTER(255),
  structured_data TEXT,
  message TEXT
);

CREATE INDEX events_emitted_at ON events(emitted_at);

https://github.com/jzimmek/em-postgresql-sequel
https://github.com/levicook/goliath-postgres-spike
https://github.com/jtoy/em-postgres