require 'oauth_util.rb'

class Yahoo
  # GAME_KEY      = ENV['game_key']
  # LEAGUE_NUMBER = ENV['league_number']
  # GAME_KEY      =
  # LEAGUE_NUMBER =
  LEAGUE_KEY    = "#{GAME_KEY}.l.#{LEAGUE_NUMBER}"
  BASE_URL      = 'http://fantasysports.yahooapis.com/fantasy/v2'
  LEAGUE_URL    = "#{BASE_URL}/league/#{LEAGUE_KEY}"

  def self.oAuth
    o                 = OauthUtil.new
    # o.consumer_key    = ENV['consumer_key']
    o.consumer_key    = 'dj0yJmk9TVZsQThOUmVYWFZuJmQ9WVdrOU5XUndZVVo2Tm5FbWNHbzlNQS0tJnM9Y29uc3VtZXJzZWNyZXQmeD1lYg'
    # o.consumer_secret = ENV['consumer_secret']
    o.consumer_secret = '37580f718fe723c05de1f6562572177255c8b83f'
    o
  end

  def self.get_xml (url)
    o          = oAuth
    parsed_url = URI.parse(url)
    Net::HTTP.start(parsed_url.host) do |http|
      req       = Net::HTTP::Get.new "#{ parsed_url.path }?#{ o.sign(parsed_url).query_string }"
      @response = http.request(req).body
    end

  end

  def self.get_league_metadata
    url = "#{LEAGUE_URL}/metadata"
    doc = get_xml(url)
    get_league_metadata_from_xml(doc)
  end


  def self.get_all_players(limit = 1300)
    players_url = "#{LEAGUE_URL}/players"
    players     = []

    (0..limit).step(25) do |i| #have to pull down in batches
      batch_url = "#{players_url};start=#{i};count=25"
      puts batch_url
      doc = get_xml (batch_url)
      doc.css('player').each do |player_xml|
        players << get_player_hash_from_xml(player_xml)
      end
    end
  end
end