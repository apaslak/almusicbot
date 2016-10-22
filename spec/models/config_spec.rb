require 'spec_helper'
require_relative '../../models/config'

%w(database_url
   discord_token
   discord_token
   discord_client_id
   yt_refresh_token
   yt_client_id
   yt_client_secret
   debug).each do |secret|
  RSpec.describe Config, "##{secret}" do
    subject { Config.new }

    context 'no file to load, ENV specified' do
      before do
        allow(File).to receive(:file?).and_return(false)
        allow(ENV).to receive(:[]).with(secret.upcase).and_return('foobar1')
      end

      it 'sets it from the ENV data' do
        expect(subject.send(secret)).to eq('foobar1')
      end
    end

    context 'loading from file, no ENV specified' do
      before do
        allow(File).to receive(:file?).and_return(true)
        allow(YAML).to receive(:load_file).and_return(secret => 'foobar2')
        allow(ENV).to receive(:[]).with(secret.upcase).and_return(nil)
      end

      it 'sets it from the file data' do
        expect(subject.send(secret)).to eq('foobar2')
      end
    end

    context 'loading from file and ENV specified' do
      before do
        allow(File).to receive(:file?).and_return(true)
        allow(YAML).to receive(:load_file).and_return(secret => 'foobar3')
        allow(ENV).to receive(:[]).with(secret.upcase).and_return('foo')
      end

      it 'prioritizes the ENV data' do
        expect(subject.send(secret)).to eq('foo')
      end
    end
  end
end
