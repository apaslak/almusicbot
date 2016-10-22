require 'spec_helper'
require 'json'
require_relative '../../resources/rest_client_wrapper'

RSpec.describe RestClientWrapper do
  let(:json_response) { spy('json_response') }
  let(:response) { spy('response') }
  let(:url) { 'http://google.com' }
  let(:headers) { 'something' }

  describe '#post' do
    let(:body) { { foo: 'bar' } }

    before do
      allow(RestClient).to receive(:post).with(url, body, headers).and_return(json_response)
      allow(JSON).to receive(:parse).with(json_response, symbolize_names: true).and_return(response)
      subject.post(url, body, headers)
    end

    it 'parses the response' do
      expect(JSON).to have_received(:parse).with(json_response, symbolize_names: true)
    end
  end

  describe '#get' do
    before do
      allow(RestClient).to receive(:get).with(url, headers).and_return(json_response)
      allow(JSON).to receive(:parse).with(json_response, symbolize_names: true).and_return(response)
      subject.get(url, headers)
    end

    it 'parses the response' do
      expect(JSON).to have_received(:parse).with(json_response, symbolize_names: true)
    end
  end
end
