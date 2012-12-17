require './config'
require 'goliath/rack/templates'

class HerokuLogDrain < Goliath::API

  include Goliath::Rack::Templates

  # If we've explicitly set auth, check for it. Otherwise, buyer-beware!
  use Rack::Auth::Basic, "Heroku Log Drain" do |username, password|
    protected? ? authorized?(username, password) : true
  end

  def response(env)
    case env['PATH_INFO']
    when '/drain' then
      store_log(env[Goliath::Request::RACK_INPUT].read) if(env[Goliath::Request::REQUEST_METHOD] == 'POST')
      [200, {}, "drained"]
    when '/' then
      [200, {}, haml(:index, :locals => {
        :protected => self.class.protected?, :username => ENV['HTTP_AUTH_USER'], :password => ENV['HTTP_AUTH_PASSWORD'],
        :event_count => DB[:events].count, :env => env
      })]
    else
      raise Goliath::Validation::NotFoundError
    end    
  end

  private

  def store_log(log_str)
    event_data = HerokuLogParser.parse(log_str)
    DB[:events].multi_insert(event_data, :commit_every => 10)
  end

  def self.protected?
    ['HTTP_AUTH_USER', 'HTTP_AUTH_PASSWORD'].any? { |v| !ENV[v].nil? && ENV[v] != '' }
  end

  def self.authorized?(u, p)
    [u, p] == [ENV['HTTP_AUTH_USER'], ENV['HTTP_AUTH_PASSWORD']]
  end
end