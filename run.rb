require 'discordrb'
require 'json'
require 'pg'
require 'rest-client'
require 'sequel'

require_relative 'models/config'
require_relative 'models/discord_bot'
require_relative 'modules/daily_music_playlist'
require_relative 'modules/ping_pong'

BOT = DiscordBot.new
BOT.bot.include! DailyMusicPlaylist
BOT.bot.include! PingPong

BOT.bot.run
