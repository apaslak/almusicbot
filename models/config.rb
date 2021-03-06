require 'yaml'

# Loads in configuration variables from a file or ENV
class Config
  CONFIG_VARS = [
    :database_url,
    :discord_token,
    :discord_client_id,
    :yt_refresh_token,
    :yt_client_id,
    :yt_client_secret,
    :debug,
    :privacy_status
  ].freeze

  def initialize
    load_config_from_file
    @config = {}
    create_methods
  end

  def create_methods
    CONFIG_VARS.each do |secret|
      self.class.send(:define_method, secret) do
        if @config[secret].nil?
          @config[secret] = ENV[secret.to_s.upcase] || @secrets[secret.to_s]
        else
          @config[secret]
        end
      end
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
