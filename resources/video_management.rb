def access_token
  token = database_connection['SELECT * FROM access_token ORDER BY id DESC LIMIT 1'].first
  created_at = DateTime.parse("#{token[:created_at]}-05:00")

  if created_at.nil? || ((DateTime.now - created_at) * 24).to_i >= 1
    refresh_access_token
  else
    token[:token]
  end
end

def refresh_access_token
  grant_type = 'refresh_token'
  url = "https://accounts.google.com/o/oauth2/token"
  body = {
    grant_type: grant_type,
    client_id: BOT.config.yt_client_id,
    client_secret: BOT.config.yt_client_secret,
    refresh_token: BOT.config.yt_refresh_token
  }
  headers = {'Content-Type': 'application/x-www-form-urlencoded'}
  response = post(url, body, headers)
  database_connection[:access_token].insert(:token => response['access_token'], :created_at => DateTime.now)
  response['access_token']
end

def create_new_playlist(title)
  body = {
    "snippet": { "title": "#{title}" },
    "status": { "privacyStatus": "public" }
  }
  headers = { 'Authorization': "Bearer #{access_token}", 'Content-Type': 'application/json'}
  response = post(url('playlists', 'snippet,status'), JSON.generate(body), headers)
  database_connection[:playlists].insert(:title => title, :yt_id => response['id'])
  response['id']
end

def add_video(yt_id, video_id)
  body = {
    "snippet": {
      "playlistId": yt_id,
      "resourceId": {
        "kind": "youtube#video",
        "videoId": video_id
      }
    }
  }
  response = post(url('playlistItems', 'snippet'), JSON.generate(body), headers)
end
