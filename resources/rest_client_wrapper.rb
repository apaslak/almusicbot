require 'rest-client'

# Wrap RestClient so I'm not stuck with it later
module RestClientWrapper
  def self.post(url, body, headers = {})
    response = RestClient.post(url, body, headers)
    JSON.parse(response, symbolize_names: true)
  end

  def self.get(url, headers = {})
    response = RestClient.get(url, headers)
    JSON.parse(response, symbolize_names: true)
  end
end
