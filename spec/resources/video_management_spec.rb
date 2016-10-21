require 'spec_helper'
require_relative '../../resources/video_management'

RSpec.describe "#access_token" do
  let(:almost_one_hour_ago) { ((1.0/24)/60)*59 } # 59 minutes
  let(:database_connection) { double("database_connection") }
  let(:created_at) { DateTime.now - almost_one_hour_ago }

  before do
    allow(database_connection).to receive(:[]).with('SELECT * FROM access_token ORDER BY id DESC LIMIT 1').
      and_return([token: 'foo', created_at: created_at])
  end

  it "gets the most recent access token from the database" do
    expect(access_token).to eq('foo')
  end

  context "an expired token" do
    let(:one_hour_ago) { 1.0/24 }
    let(:created_at) { DateTime.now - one_hour_ago }
    let(:refresh_access_token) { double("refresh_access_token") }

    it "refreshes the access token" do
      expect(access_token).to eq(refresh_access_token)
    end
  end
end

RSpec.describe "#refresh_access_token" do
  let(:bot) do
    double("BOT", config: { yt_client_id: 12345,
                            yt_client_secret: 'itsasecret',
                            yt_refresh_token: 'itsarefreshtoken' })
  end

  it "thing" do
    binding.pry
  end
end

RSpec.describe "#create_new_playlist" do
end

RSpec.describe "#add_video" do
end
