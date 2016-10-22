# A bot to hold the Discordrb bot and all the config vars
class DiscordBot
  attr_accessor :config
  attr_accessor :bot

  def initialize
    @config = Config.new
    @bot = Discordrb::Bot.new(token: config.discord_token,
                              client_id: config.discord_client_id)
  end
end
