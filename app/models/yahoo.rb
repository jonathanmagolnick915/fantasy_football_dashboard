require 'oauth_util.rb'
require 'net/http'
require 'nokogiri'
require 'open-uri'

class Yahoo
  GAME_KEY      = ENV['game_key']
  LEAGUE_NUMBER = ENV['league_number']
  LEAGUE_KEY    = "#{GAME_KEY}.l.#{LEAGUE_NUMBER}"
  BASE_URL      = 'https://fantasysports.yahooapis.com/fantasy/v2'
  LEAGUE_URL    = "#{BASE_URL}/league/#{LEAGUE_KEY}"

  def self.get_xml(url)
    url = URI.parse(url)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(url)
    request['cache-control'] = 'no-cache'
    request['postman-token'] = '4e23a1cf-6da1-fac0-084c-f56bd30ff210'
    request['authorization'] = 'Bearer tHN4wQXOslmtLhsI.boewIWD45Wctbjf4PbJcKNlILHep2cann_Ax6CBgbj6D1anHp5cGs_5gBW1L7lMiaWBUrfuZeli_nrCVUbhr.KbRyQxZAjHLYBRyYuVdZRvboqmFkSmIeICsKjAxGH4MJj68QNrhWP0sFxyC9yBhCwwcxj1D15kH0dasPlui_2iqEL2EXY5bdrBjAhKCElOml_A6WKXeyrlSdvu2LuG0b7JPqUVM5V3kkwNHK8VSacb0T32.zAVAh8QSFiPIHOBsWqlmDGByu64sHWkxsfSpp4glE_06Lp54QKu6kuF0ApMXxDZBje7xxOmSbcBv3.5gaa6oBCcS49PRrGmH7xRQh3FPo.DpxLXA2.l9lLPAs7KsbpHczMTxm.PvP1s2pdL1.XCYWdZt.cJ0OqKHOLcFbFQfzVLie0Ilx6DvbXnATkUQTed0ZvpTPLnMXvubpb5WAkW__JHUTF.d9zpIOMZRsGvVla4m32PvC97dHE4Lt5D05_pLGz5.izw0Hqe.gKLKCtqcZJKC3L.4QI7m6MM3y3SZdyJX9a4ygK8LSoX1yIAZ8wdIQpL8PIi8ubSoBvNy9EaoiYLYPnVIkh9U2CA2UQPFOf6Ia2neN6OKviooFP_WvjoFxkSaoSqirTu6_8KKCQRMritNFC3PjiNeLbDzVoTtS7puIVxVs1mG71OY4Aq.BbeZkw9FxoIizUqUrrArrREg6bzYNuJLYbVCsx87RFWmOSPPDo2TtQ3ZUctociAGs7jgfqRK65cFFAdtOsuMRs8MmNJWGatxHzqIEA5B6mRKxjsJ1HWhIiY6CjN6abpP6M8llhJtthiP55bT8OahW.xWmyc.yKoZ6FUwP3_DvnSh.zGNXIlr_C2uB2WozqZqC66R9ci784J.8bMnN.z7ekoBc9FCgIdQDTaFuJEGFdlLFiEmqo5gUkPQ8XHqNKb5UAdkp1VrTl2KWmZHcVXfUCNdWLFNdO_HobKSyfFUxec193_IhT6d8ZfiCiCFrFPKUeVQFVLl0Mmwytp2jRBaFb56Kz.CkV.nue34seMDp0pUrTIVxm4e1rnpfZDOojPqCKIaTwpG3oJZL5KAZyE'

    @response = Nokogiri::XML(http.request(request).body)
    @response
  end

  def self.get_league_metadata
    url = "#{LEAGUE_URL}/metadata"
    doc = get_xml(url)
    get_league_metadata_from_xml(doc)
  end


  def self.get_all_players(limit = 1300)
    players_url = "#{LEAGUE_URL}/players"
    players = []

    (0..limit).step(25) do |i| #have to pull down in batches
      batch_url = "#{players_url};start=#{i};count=25"
      doc = get_xml(batch_url)
      doc.css('player').each do |player_xml|
        players << get_player_hash_from_xml(player_xml)
      end
    end
    players
  end

  def self.get_teams
    teams = []
    teams_url = "#{LEAGUE_URL}/teams"
    doc = get_xml (teams_url)
    doc.css('team').each do |team_xml|
      teams << get_team_hash_from_xml(team_xml)
    end

    teams
  end

  def self.get_players_from_team(yahoo_team_key)
    players = []
    #http://developer.yahoo.com/fantasysports/guide/team-resource.html
    team_url = "#{BASE_URL}/team/#{yahoo_team_key}/roster"
    p team_url
    doc = get_xml(team_url)
    doc.css('player').each do |player_xml|
      players << get_player_hash_from_xml(player_xml)
    end
    players
    end

  ##############################################################################
  # Turn raw XML into hashes
  ##############################################################################

  def self.get_team_hash_from_xml(xml)
    {
        yahoo_key:  xml.css('team_key').inner_html,
        yahoo_id:   xml.css('team_id').inner_html,
        name:       xml.css('name').inner_html,
        yahoo_owner_id: xml.css('manager_id').inner_html,
        yahoo_owner_name: xml.css('nickname').inner_html,
    }
  end

  def self.get_player_hash_from_xml(xml)
    {
        yahoo_id:    xml.css('player_id').inner_html.to_i,
        yahoo_key:   xml.css('player_key').inner_html,
        first_name:  xml.css('ascii_first').inner_html,
        last_name:   xml.css('ascii_last').inner_html,
        bye_week:    xml.css('bye_weeks/week').inner_html.to_i,
        position:    xml.css('display_position').inner_html,
        active:      xml.css('selected_position/position').inner_html == "BN" ? false : true,
        team:        xml.css('editorial_team_abbr').inner_html.upcase
    }
  end

  def self.get_league_metadata_from_xml(xml)
    {
        league_key:     LEAGUE_KEY,
        league_name:    xml.css('name').inner_html,
        current_week:   xml.css('current_week').inner_html,
        game_key:       GAME_KEY,
        league_number:  LEAGUE_NUMBER
    }
  end

 end