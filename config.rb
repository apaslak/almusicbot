require 'yaml'

class Config
  def initialize
    load_config_from_file
    @config = {}
  end

  def database_url
    if @config[:database_url].nil?
      @config[:database_url] = ENV['DATABASE_URL'] || @secrets['database_url']
    else
      @config[:database_url]
    end
  end

  def discord_token
    if @config[:discord_token].nil?
      @config[:discord_token] = ENV['DISCORD_TOKEN'] || @secrets['discord_token']
    else
      @config[:discord_token]
    end
  end

  def discord_client_id
    if @config[:discord_client_id].nil?
      @config[:discord_client_id] = ENV['DISCORD_CLIENT_ID'] || @secrets['discord_client_id']
    else
      @config[:discord_client_id]
    end
  end

  def yt_refresh_token
    if @config[:yt_refresh_token].nil?
      @config[:yt_refresh_token] = ENV['YT_REFRESH_TOKEN'] || @secrets['yt_refresh_token']
    else
      @config[:yt_refresh_token]
    end
  end

  def yt_client_id
    if @config[:yt_client_id].nil?
      @config[:yt_client_id] = ENV['YT_CLIENT_ID'] || @secrets['yt_client_id']
    else
      @config[:yt_client_id]
    end
  end

  def yt_client_secret
    if @config[:yt_client_secret].nil?
      @config[:yt_client_secret] = ENV['YT_CLIENT_SECRET'] || @secrets['yt_client_secret']
    else
      @config[:yt_client_secret]
    end
  end

  def debug
    if @config[:debug].nil?
      @config[:debug] = ENV['DEBUG'] || @secrets['debug']
    else
      @config[:debug]
    end
  end

  private
  def load_config_from_file
    secrets_file = 'secrets.yml'
    if File.file?(secrets_file)
      @secrets ||= YAML.load_file(secrets_file)
    else
      @secrets = {}
    end
  end
end
