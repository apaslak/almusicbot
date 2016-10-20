def post(url, body, headers={})
  response = RestClient.post(url, body, headers)
  JSON.parse(response)
end

def get(url, headers={})
  response = RestClient.get(url, headers)
  JSON.parse(response)
end

def url(resource, part)
  "https://www.googleapis.com/youtube/v3/#{resource}?part=#{part}"
end

def headers
  { 'Authorization': "Bearer #{access_token}", 'Content-Type': 'application/json'}
end
