require 'spec_helper'
require 'ostruct'
require 'json'
require_relative '../../resources/video_management'

RSpec.describe VideoManagement do
  let(:database_connection) { double('connection') }

  before do
    allow(DatabaseConnection).to receive(:connection).and_return(database_connection)
  end

  describe '#playlist_url' do
    it 'string interpolates with the provided info' do
      expect(subject.playlist_url('foo', 'bar')).to eq('https://www.googleapis.com/youtube/v3/foo?part=bar')
    end
  end

  describe '#access_token' do
    let(:almost_one_hour_ago) { ((1.0 / 24) / 60) * 59 } # 59 minutes
    let(:created_at) { DateTime.now - almost_one_hour_ago }

    before do
      allow(database_connection).to receive(:[])
        .with('SELECT * FROM access_token ORDER BY id DESC LIMIT 1')
        .and_return([token: 'foo', created_at: created_at])
    end

    it 'gets the most recent access token from the database' do
      expect(subject.access_token).to eq('foo')
    end

    context 'an expired token' do
      let(:one_hour_ago) { 1.0 / 24 }
      let(:created_at) { DateTime.now - one_hour_ago }
      let(:refresh_access_token) { double('refresh_access_token') }

      it 'refreshes the access token' do
        allow(subject).to receive(:refresh_access_token).and_return(refresh_access_token)
        expect(subject.access_token).to eq(refresh_access_token)
      end
    end
  end

  describe '#refresh_access_token' do
    let(:bot) do
      OpenStruct.new(config: OpenStruct.new(yt_client_id: 123_45,
                                            yt_client_secret: 'itsasecret',
                                            yt_refresh_token: 'itsarefreshtoken'))
    end
    let(:url) { 'https://accounts.google.com/o/oauth2/token' }
    let(:body) do
      { grant_type: 'refresh_token',
        client_id: bot.config.yt_client_id,
        client_secret: bot.config.yt_client_secret,
        refresh_token: bot.config.yt_refresh_token }
    end
    let(:headers) { { 'Content-Type': 'application/x-www-form-urlencoded' } }
    let(:now) { DateTime.now }
    let(:access_token_db) { double('access_token_db') }

    before do
      stub_const('BOT', bot)
      allow(DateTime).to receive(:now).and_return(now)
      allow(RestClientWrapper).to receive(:post)
        .with(url, body, headers).and_return(access_token: 'accesstoken')
      allow(database_connection).to receive(:[])
        .with(:access_token).and_return(access_token_db)
      allow(access_token_db).to receive(:insert)
        .with(token: 'accesstoken', created_at: now)
    end

    it 'updates the access token in the database' do
      subject.refresh_access_token
      expect(access_token_db).to have_received(:insert).with(token: 'accesstoken', created_at: now)
    end

    it 'returns the new access token' do
      expect(subject.refresh_access_token).to eq('accesstoken')
    end
  end

  describe '#create_new_playlist' do
    let(:title) { 'foobard' }
    let(:body) do
      { snippet: { title: title },
        status: { privacyStatus: 'public' } }
    end
    let(:url) { 'https://www.googleapis.com/youtube/v3/playlists?part=snippet,status' }
    let(:access_token) { double('access_token') }
    let(:headers) do
      { 'Authorization': "Bearer #{access_token}",
        'Content-Type': 'application/json' }
    end
    let(:playlist) { { title: title, yt_id: playlist_id } }
    let(:playlist_id) { 'playlistid' }
    let(:playlist_db) { double('playlist_db') }

    before do
      allow(subject).to receive(:playlist_url).and_return(url)
      allow(RestClientWrapper).to receive(:post)
        .with(url, body, headers).and_return(id: playlist_id)
      allow(subject).to receive(:access_token).and_return(access_token)
      allow(database_connection).to receive(:[])
        .with(:playlists).and_return(playlist_db)
      allow(playlist_db).to receive(:insert)
        .with(title: title, yt_id: playlist_id).and_return(playlist)
    end

    it 'adds the playlist to the database' do
      subject.create_new_playlist(title)
      expect(playlist_db).to have_received(:insert).with(title: title, yt_id: playlist_id)
    end

    it 'returns the playlist' do
      expect(subject.create_new_playlist(title)).to eq(playlist)
    end
  end

  describe '#add_video' do
    let(:yt_id) { 'youtubeid' }
    let(:video_id) { 'videoid' }
    let(:body) do
      JSON.generate(
        snippet: {
          playlistId: yt_id,
          resourceId: {
            kind: 'youtube#video',
            videoId: video_id
          }
        }
      )
    end
    let(:url) { 'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet' }
    let(:access_token) { double('access_token') }
    let(:headers) do
      { 'Authorization': "Bearer #{access_token}",
        'Content-Type': 'application/json' }
    end

    before do
      allow(subject).to receive(:playlist_url).and_return(url)
      allow(subject).to receive(:access_token).and_return(access_token)
    end

    it 'adds the video to the playlist' do
      expect(RestClientWrapper).to receive(:post)
        .with(url, body, headers)
      subject.add_video(yt_id, video_id)
    end
  end

  describe '#last_playlist' do
    let(:created_at) { DateTime.now }

    it 'gets the last playlist from the database' do
      expect(database_connection).to receive(:[])
        .with('SELECT * FROM playlists ORDER BY id DESC LIMIT 1')
        .and_return([token: 'foo', created_at: created_at])
      subject.last_playlist
    end

    context 'no playlists' do
      it 'returns nil' do
        allow(database_connection).to receive(:[])
          .with('SELECT * FROM playlists ORDER BY id DESC LIMIT 1')
          .and_return([])
        expect(subject.last_playlist).to be_nil
      end
    end
  end
end
