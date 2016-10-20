def database_connection
  @conn ||= Sequel.connect(BOT.config.database_url)
end
