Sequel.migration do
  transaction

  up do
    run <<-EOS
      CREATE EXTENSION IF NOT EXISTS hstore;

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
        message TEXT,
        original TEXT
      );

      CREATE INDEX events_emitted_at ON events(emitted_at);
      CREATE INDEX events_proc_id ON events(proc_id);
      CREATE INDEX events_appname ON events(appname);
      CREATE INDEX events_received_at ON events(received_at);

    EOS
  end

  down { run "DROP TABLE IF EXISTS events;" }
end