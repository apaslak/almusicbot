# Basic request/response testing
module PingPong
  extend Discordrb::EventContainer

  message(with_text: 'Ping!') do |event|
    event.respond 'Pong!'
  end
end
