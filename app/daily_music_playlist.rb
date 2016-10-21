# Module that handles listening for youtube links
# and adding them to an appropriate youtube playlist
module DailyMusicPlaylist
  extend Discordrb::EventContainer
  CHANNELS = ['music'].freeze

  def self.listening_to(channel_name)
    CHANNELS.include?(channel_name)
  end

  def self.last_playlist
    query = 'SELECT * FROM playlists ORDER by id DESC LIMIT 1'
    result = database_connection[query]
    result.first
  end

  def self.video_id_from_message(message)
    youtube_regex = %r{(https?:\/\/(www\.)?youtube.com\/watch\?)v=([^\&]+)}
    short_yt_regex = %r{(https?:\/\/(www\.)?youtu\.be\/)([^\?]+)}
    matched = youtube_regex.match(message) || short_yt_regex.match(message)
    matched[3] if matched
  end

  def self.need_new_list?(todays_date, last_list)
    return true if last_list.nil?
    last_list[:title] != todays_date
  end

  def self.find_playlist(todays_date, last_playlist)
    if need_new_list?(todays_date, last_playlist)
      create_new_playlist(todays_date)
    else
      last_playlist[:yt_id]
    end
  end

  def self.do_work(video_id)
    todays_date = Time.now.strftime('%m/%d/%Y')
    last_playlist = last_playlist

    puts 'skipped' if last_playlist && last_playlist[:yt_id] == video_id

    yt_id = find_playlist(todays_date, last_playlist)
    add_video(yt_id, video_id)
  end

  message(containing: 'youtube.com/') do |event|
    if listening_to(event.channel.name)
      video_id = video_id_from_message(event.message.content)
      do_work(video_id)
      event.respond 'added' if BOT.config.debug
    end
  end

  message(exact_text: '!daily_playlist') do |event|
    if listening_to(event.channel.name)
      url = "https://www.youtube.com/playlist?list=#{last_playlist[:yt_id]}"
      event.respond url
    end
  end
end
