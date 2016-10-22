require 'spec_helper'
require 'discordrb'
require_relative '../../modules/daily_music_playlist'

RSpec.describe DailyMusicPlaylist do
  shared_examples 'a match' do |url|
    let(:id) { 'ReXRXxbeZ_I' }

    it 'matches' do
      expect(subject.match(url)).to_not be_nil
      expect(subject.match(url)[3]).to eq(id)
    end
  end

  describe 'LONG_YT_REGEX' do
    subject { DailyMusicPlaylist::LONG_YT_REGEX }

    context 'https or http' do
      %w(https://www.youtube.com/watch?v=ReXRXxbeZ_I
         http://www.youtube.com/watch?v=ReXRXxbeZ_I).each do |url|
        it_behaves_like 'a match', url
      end
    end

    context 'with www or without' do
      %w(https://www.youtube.com/watch?v=ReXRXxbeZ_I
         https://youtube.com/watch?v=ReXRXxbeZ_I).each do |url|
        it_behaves_like 'a match', url
      end
    end

    it "just 'youtube' or 'youtube.com'" do
      expect(subject.match('youtube')).to be_nil
      expect(subject.match('youtube.com')).to be_nil
    end

    context 'a playlist' do
      url = 'https://www.youtube.com/watch?v=ReXRXxbeZ_I&list=PLoK8nlYJWv_k2ZiybfhYBSBYKxoMHWzNc&index=1'
      it_behaves_like 'a match', url
    end
  end

  describe 'SHORT_YT_REGEX' do
    let(:id) { 'ReXRXxbeZ_I' }

    subject { DailyMusicPlaylist::SHORT_YT_REGEX }

    context 'https or http' do
      %w(https://youtu.be/ReXRXxbeZ_I
         http://youtu.be/ReXRXxbeZ_I).each do |url|
        it_behaves_like 'a match', url
      end
    end

    context 'with www or without' do
      %w(https://www.youtu.be/ReXRXxbeZ_I
         https://youtu.be/ReXRXxbeZ_I).each do |url|
        it_behaves_like 'a match', url
      end
    end

    it "does not match just 'youtu.be'" do
      expect(subject.match('youtu.be')).to be_nil
    end

    context 'a playlist or start time' do
      %w(https://youtu.be/ReXRXxbeZ_I?list=PLoK8nlYJWv_k2ZiybfhYBSBYKxoMHWzNc
         https://youtu.be/ReXRXxbeZ_I?t=2s).each do |url|
        it_behaves_like 'a match', url
      end
    end
  end

  describe '#listening_to' do
    it 'searches the channels list for a match' do
      expect(subject.listening_to('foo')).to be(false)
      expect(subject.listening_to('music')).to be(true)
    end
  end

  describe '#video_id_from_message' do
    it 'returns the id' do
      url = 'https://youtu.be/ReXRXxbeZ_I?t=2s'
      message = "foobar #{url}"
      expect(subject.video_id_from_message(message)).to eq('ReXRXxbeZ_I')
    end

    context 'no match' do
      it 'returns nil' do
        expect(subject.video_id_from_message('foobar')).to be_nil
      end
    end
  end

  describe '#need_new_list?' do
    it "checks if the most recent playlist matches today's date" do
      last_playlist = { title: '10/09/2016' }
      expect(subject.need_new_list?('10/10/2016', last_playlist)).to be(true)

      last_playlist = { title: '10/10/2016' }
      expect(subject.need_new_list?('10/10/2016', last_playlist)).to be(false)
    end

    context 'no playlists' do
      it 'returns true' do
        expect(subject.need_new_list?('10/10/2016', nil)).to be(true)
      end
    end
  end

  describe '#find_playlist_id' do
    let(:yesterdays_date) { '10/09/2016' }
    let(:todays_date) { '10/10/2016' }

    it 'pulls the id off the last playlist' do
      last_playlist = { title: todays_date, yt_id: 'foo_id' }
      allow(subject).to receive(:need_new_list?).with(todays_date, last_playlist).and_return(false)
      expect(subject.find_playlist_id(todays_date, last_playlist)).to eq(last_playlist[:yt_id])
    end

    context 'last playlist passed in was nil' do
      it 'delegates to VideoManagement to create a new list' do
        expect(VideoManagement).to receive(:create_new_playlist)
          .with(todays_date).and_return(yt_id: 'foo')
        expect(subject.find_playlist_id(todays_date, nil)).to eq('foo')
      end
    end

    context "today's playlist doesn't exist yet" do
      it 'delegates to VideoManagement to create a new list' do
        last_playlist = { title: yesterdays_date, yt_id: 'foobar_id' }
        expect(VideoManagement).to receive(:create_new_playlist)
          .with(todays_date).and_return(yt_id: 'new_list')
        expect(subject.find_playlist_id(todays_date, last_playlist)).to eq('new_list')
      end
    end
  end

  describe '#do_work' do
    let(:todays_date) { Time.now.strftime('%m/%d/%Y') }
    let(:video_id) { 'ReXRXxbeZ_I' }
    let(:last_playlist) { { title: todays_date, yt_id: 'foo_id' } }

    before do
      allow(VideoManagement).to receive(:last_playlist).and_return(last_playlist)
      allow(subject).to receive(:find_playlist_id).with(todays_date, last_playlist)
        .and_return(last_playlist[:yt_id])
      allow(VideoManagement).to receive(:add_video).with(last_playlist[:yt_id], video_id)
    end

    it 'finds the playlist' do
      subject.do_work('ReXRXxbeZ_I')
      expect(subject).to have_received(:find_playlist_id).with(todays_date, last_playlist)
    end

    it 'adds the video to the playlist' do
      subject.do_work('ReXRXxbeZ_I')
      expect(VideoManagement).to have_received(:add_video).with(last_playlist[:yt_id], video_id)
    end

    context 'recommended video link is the daily playlist' do
      before do
        subject.do_work(last_playlist[:yt_id])
      end

      it 'does not try to find the playlist' do
        expect(subject).to_not have_received(:find_playlist_id)
      end

      it 'does not try to add the video to any playlist' do
        expect(VideoManagement).to_not have_received(:add_video)
      end
    end
  end
end
