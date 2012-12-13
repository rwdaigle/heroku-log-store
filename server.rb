require 'bundler/setup'
Bundler.require

DB = Sequel.connect(ENV['DATABASE_URL'] || "postgres://localhost/clorox",
  :max_connections => ENV['MAX_DB_CONNECTIONS'] ? ENV['MAX_DB_CONNECTIONS'].to_i : 4
)
DB.extension :pg_hstore

class Hello < Goliath::API
  def response(env)
    DB[:events].insert([:emitted_at, :received_at, :data], [Time.now.utc, Time.now.utc, {'key' => 'value', 'at' => 'event-start'}.hstore])
    [200, {}, DB[:events].order(:id).reverse.limit(25).collect { |r| r[:id] }.join(', ')]
  end
end

__END__

CREATE EXTENSION hstore;

CREATE table events (
  id SERIAL8 PRIMARY KEY,
  emitted_at TIMESTAMP WITH TIME ZONE,
  received_at TIMESTAMP WITH TIME ZONE,
  data HSTORE
);

CREATE INDEX events_emitted_at ON events(emitted_at);
CREATE INDEX events_received_at ON events(received_at);
CREATE INDEX events_data ON events USING GIN(data);

https://github.com/jzimmek/em-postgresql-sequel
https://github.com/levicook/goliath-postgres-spike
https://github.com/jtoy/em-postgres