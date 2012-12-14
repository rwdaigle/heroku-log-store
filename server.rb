require 'bundler/setup'
Bundler.require
STDOUT.sync = true

DB = Sequel.connect(ENV['DATABASE_URL'] || "postgres://localhost/clorox",
  :max_connections => ENV['MAX_DB_CONNECTIONS'] ? ENV['MAX_DB_CONNECTIONS'].to_i : 4
)
DB.extension :pg_hstore

class Parsley

  LineRe = /\<\d+\>1 (\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\+00:00) [a-z0-9-]+ ([a-z0-9\-\_\.]+) ([a-z0-9\-\_\.]+) \- (.*)$/

  attr_reader :data
  attr_accessor :format

  def initialize(data, format = :heroku)
    self.format = format
    @data = data
  end

  # http://tools.ietf.org/html/rfc5424#page-8
  # frame <prority>version time hostname <appname-missing> procid msgid [structured data] msg
  # 120 <40>1 2012-11-30T06:45:29+00:00 heroku web.3 d.73ea7440-270a-435a-a0ea-adf50b4e5f5a - State changed from starting to up
  def lines(&block)
    d = data
    while d && d.length > 0
      if matching = d.match(/^(\d+) /) # if have a counting frame, use it
        num_bytes = matching[1].to_i
        frame_offset = matching[0].length
        line_end = frame_offset + num_bytes
        msg = data[frame_offset..line_end]
        yield msg
        d = d[line_end..d.length]
      elsif matching = d.match(/\n/) # Newlines = explicit message delimiter
        d = matching.post_match
      else
        STDERR.puts("Unable to parse: #{d}")
      end
    end
  end

  def events(&block)
    lines do |line|
      if(matching = line.match(LineRe))
        yield Time.parse(matching[1]).utc, matching[2], matching[3], matching[4]
      end
    end
  end
end

class CloroxServer < Goliath::API

  def response(env)

    if(env[Goliath::Request::REQUEST_METHOD] == 'POST')
      parsley = Parsley.new(env[Goliath::Request::RACK_INPUT].read)
      parsley.events do |emitted_at, process, drain_token, data|
        STDOUT.puts(emitted_at.to_s + " -- " + data)
      end
    end

    # DB[:events].insert([:emitted_at, :received_at, :data], [Time.now.utc, Time.now.utc, {'key' => 'value', 'at' => 'event-start'}.hstore])
    # [200, {}, DB[:events].order(:id).reverse.limit(25).collect { |r| r[:id] }.join(', ')]

    [200, {}, "ok"]
  end
end

__END__

CREATE EXTENSION hstore;

// <prority>version time hostname <appname-missing> procid msgid [structured data] msg

CREATE table events (
  id SERIAL8 PRIMARY KEY,
  emitted_at TIMESTAMP WITH TIME ZONE,
  received_at TIMESTAMP WITH TIME ZONE,
  syslog_version INTEGER,
  hostname CHARACTER(255),
  appname CHARACTER(48),
  procid CHARACTER(128),
  msgid CHARACTER(32)
  msg TEXT
);

CREATE INDEX events_emitted_at ON events(emitted_at);

https://github.com/jzimmek/em-postgresql-sequel
https://github.com/levicook/goliath-postgres-spike
https://github.com/jtoy/em-postgres