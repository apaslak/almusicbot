# Connects to the database
module DatabaseConnection
  def self.connection
    @conn ||= Sequel.connect(BOT.config.database_url)
  end
end
