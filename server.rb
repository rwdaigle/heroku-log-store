require 'config'

class CloroxServer < Goliath::API

  def response(env)

    if(env[Goliath::Request::REQUEST_METHOD] == 'POST')
      LOG_PARSER.events(env[Goliath::Request::RACK_INPUT].read) do |event|
        DB[:events].insert(
          Parsley::SYSLOG_KEYS,
          Parsley::SYSLOG_KEYS.collect { |k| event[k] }
        )
      end
    end

    [200, {}, "ok"]
  end
end

__END__

https://github.com/jzimmek/em-postgresql-sequel
https://github.com/levicook/goliath-postgres-spike
https://github.com/jtoy/em-postgres