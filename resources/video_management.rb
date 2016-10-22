require_relative 'database_connection'
require_relative 'rest_client_wrapper'

# Logic for playlist creation
# and adding videos to playlists
module VideoManagement
  include DatabaseConnection
  include RestClientWrapper

  def self.playlist_url(resource, part)
    "https://www.googleapis.com/youtube/v3/#{resource}?part=#{part}"
  end

  def self.access_token
    query = 'SELECT * FROM access_token ORDER BY id DESC LIMIT 1'
    token = DatabaseConnection.connection[query].first
    created_at = DateTime.parse("#{token[:created_at]}-05:00")

    if created_at.nil? || ((DateTime.now - created_at) * 24).to_i >= 1
      refresh_access_token
    else
      token[:token]
    end
  end

  def self.refresh_access_token
    url = 'https://accounts.google.com/o/oauth2/token'
    body = {
      grant_type: 'refresh_token',
      client_id: BOT.config.yt_client_id,
      client_secret: BOT.config.yt_client_secret,
      refresh_token: BOT.config.yt_refresh_token
    }
    headers = { 'Content-Type': 'application/x-www-form-urlencoded' }
    response = RestClientWrapper.post(url, body, headers)
    DatabaseConnection.connection[:access_token]
                      .insert(token: response[:access_token], created_at: DateTime.now)
    response[:access_token]
  end

  def self.create_new_playlist(title)
    body = {
      snippet: { title: title },
      status: { privacyStatus: 'public' }
    }
    headers = { 'Authorization': "Bearer #{access_token}",
                'Content-Type': 'application/json' }
    response = RestClientWrapper.post(playlist_url('playlists', 'snippet,status'), body, headers)
    playlist = { title: title, yt_id: response[:id] }
    DatabaseConnection.connection[:playlists].insert(playlist)
    playlist
  end

  def self.add_video(yt_id, video_id)
    body = {
      'snippet': {
        'playlistId': yt_id,
        'resourceId': {
          'kind': 'youtube#video',
          'videoId': video_id
        }
      }
    }
    headers = { 'Authorization': "Bearer #{access_token}",
                'Content-Type': 'application/json' }
    RestClientWrapper.post(playlist_url('playlistItems', 'snippet'), JSON.generate(body), headers)
  end

  def self.last_playlist
    query = 'SELECT * FROM playlists ORDER BY id DESC LIMIT 1'
    result = DatabaseConnection.connection[query]
    result.first
  end
end
