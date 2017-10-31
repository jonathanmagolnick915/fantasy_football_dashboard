class YahooFf < ApplicationRecord

  def self.new_token
    url = URI("https://api.login.yahoo.com/oauth2/get_token")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(url)
    request["content-type"] = 'application/x-www-form-urlencoded'
    request["cache-control"] = 'no-cache'
    request["postman-token"] = '62b0d815-96f9-55fc-39fe-7e6a340f37ff'
    request.body = "client_id=dj0yJmk9Y1hWZEd0aHY2ZHBJJmQ9WVdrOWNtVkhaR3RvTm5NbWNHbzlNVFl5TmpZNE1qTTJNZy0tJnM9Y29uc3VtZXJzZWNyZXQmeD00Nw--&client_secret=bed6d08509231dbd628250613ae1df725117472f&refresh_token=ABYQ9VltPhjq_oQC2t_TVOeonGYTzkAXcz1RVAGcXoiKtJzyHEavvrW5xJw-&redirect_uri=oob&grant_type=refresh_token"

    response = JSON.parse(http.request(request).body)
    YahooFf.create(access_token: response['access_token'],
                            refresh_token: response['refresh_token'])
    return response['access_token']
  end
end
