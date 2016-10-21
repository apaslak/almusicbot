require 'discordrb'
require 'json'
require 'pg'
require 'rest-client'
require 'sequel'

require_relative 'config'
require_relative 'app/daily_music_playlist'
require_relative 'app/ping_pong'
require_relative 'resources/database_connection'
require_relative 'resources/rest_client'
require_relative 'resources/video_management'

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

BOT = DiscordBot.new
BOT.bot.include! DailyMusicPlaylist
BOT.bot.include! PingPong

BOT.bot.run
