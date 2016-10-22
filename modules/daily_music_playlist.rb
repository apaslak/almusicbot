require_relative '../resources/database_connection'
require_relative '../resources/video_management'

# Module that handles listening for youtube links
# and adding them to an appropriate youtube playlist
module DailyMusicPlaylist
  include DatabaseConnection
  extend Discordrb::EventContainer

  CHANNELS = ['music'].freeze
  LONG_YT_REGEX = %r{(https?:\/\/(www\.)?youtube.com\/watch\?)v=([^\&]+)}
  SHORT_YT_REGEX = %r{(https?:\/\/(www\.)?youtu\.be\/)([^\?]+)}

  def self.listening_to(channel_name)
    CHANNELS.include?(channel_name)
  end

  def self.video_id_from_message(message)
    matched = LONG_YT_REGEX.match(message) || SHORT_YT_REGEX.match(message)
    matched[3] if matched
  end

  def self.need_new_list?(todays_date, last_list)
    return true if last_list.nil?
    last_list[:title] != todays_date
  end

  def self.find_playlist_id(todays_date, last_playlist)
    if last_playlist.nil? || need_new_list?(todays_date, last_playlist)
      new_list = VideoManagement.create_new_playlist(todays_date)
      new_list[:yt_id]
    else
      last_playlist[:yt_id]
    end
  end

  def self.do_work(video_id)
    todays_date = Time.now.strftime('%m/%d/%Y')
    last_playlist = VideoManagement.last_playlist

    if last_playlist && last_playlist[:yt_id] == video_id
      puts 'skipped'
      return
    end

    yt_id = find_playlist_id(todays_date, last_playlist)
    VideoManagement.add_video(yt_id, video_id)
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
      last_playlist = VideoManagement.last_playlist
      url = "https://www.youtube.com/playlist?list=#{last_playlist[:yt_id]}"
      event.respond url
    end
  end
end
