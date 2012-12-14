require 'bundler/setup'
Bundler.require
STDOUT.sync = true

DB = Sequel.connect(ENV['DATABASE_URL'] || "postgres://localhost/clorox",
  :max_connections => ENV['MAX_DB_CONNECTIONS'] ? ENV['MAX_DB_CONNECTIONS'].to_i : 4
)
DB.extension :pg_hstore

class Parsley

  LineRe = /\<(\d+)\>(1) (\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\+00:00) ([a-z0-9-]+) ([a-z0-9\-\_\.]+) ([a-z0-9\-\_\.]+) \- (.*)$/

  attr_reader :data
  attr_accessor :flavor

  def initialize(data, flavor = :heroku)
    self.flavor = flavor
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
        return
      end
    end
  end

  def events(&block)
    lines do |line|
      if(matching = line.match(LineRe))
        yield event_data(matching)
      end
    end
  end

  def event_data(matching)
    event = {}
    event[:priority] = matching[1].to_i
    event[:syslog_version] = matching[2].to_i
    event[:emitted_at] = nil?(matching[3]) ? nil : Time.parse(matching[3]).utc
    event[:hostname] = interpret_nil(matching[4])
    event[:appname] = nil
    event[:proc_id] = interpret_nil(matching[5])
    event[:msg_id] = interpret_nil(matching[6])
    event[:structured_data] = nil
    event[:message] = interpret_nil(matching[7])
    event
  end

  def interpret_nil(val)
    nil?(val) ? nil : val
  end

  def nil?(val)
    val == "-"
  end
end

class CloroxServer < Goliath::API

  def response(env)

    if(env[Goliath::Request::REQUEST_METHOD] == 'POST')
      parsley = Parsley.new(env[Goliath::Request::RACK_INPUT].read)
      parsley.events do |event|
        STDOUT.puts(event[:emitted_at].to_s + " -- " + event[:message])
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
  msgid CHARACTER(32),
  structured_data_str TEXT,
  structured_data HSTORE,
  msg_str TEXT,
  msg_data HSTORE
);

CREATE INDEX events_emitted_at ON events(emitted_at);

https://github.com/jzimmek/em-postgresql-sequel
https://github.com/levicook/goliath-postgres-spike
https://github.com/jtoy/em-postgres