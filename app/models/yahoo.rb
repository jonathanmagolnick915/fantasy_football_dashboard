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
    request['authorization'] = 'Bearer WcE_cw3Oslmc0Z5e58CEwjE0lSs0iE.QGeh3h1XL2XPb4pr2XFE7f3j_OBOqpSA217A.DpcYcK47DOd9R0IoxxepcaGWZl3ITLk3FE8QLlfCQBrelekuEMTMDS8BczlZOTUZHWFambQu9j3.QtuFbwUQ_Tj5swGjvIfhJbCpGa1nRnvytHyPX62hxEWY9SMBcHDQ0QS9Br.mgKQIcyZR_bF8rMra1HfKZnVWI7JyFlibeY_Rypx7Av.1XKIiyYPXB0Ht1T7_JDAUKnbTezbqcB1b7yYFpos8p5ToX2M60Z3mOe2o2XgTu1Y9h74T.guYOhGHrEzR.43z_5Hyn2J03SwVifNZL0EUl.6ilsdtfwKD5Ma18gxVgsqRuPH39cDVRsqeVhW5hxJGjgUq8eHybOGbDF8hb5YzJ7bR_cLjibgZ__PEUU0PnLZwXVh.E.MlkzErbi67q0u2.aqL.tPtCZfcrnvwJchbw1bXj0KVPp6I2Zye12mPxTw8ifQPlPKFsuJeEEpgj9O_W_LD4ix523X7RFrSscCsacrieTid6y6yjlglJ0P7TEjC9ERPcrvOwAR52lyUiAz6Xc.A5lg7afiRRHpIqIYbKd8lYtHqdIFRYgOqa7BpvuRutpBTQsNVtSY5ZCgVhspyY_.WcD.vwWjavsrs0OG5z6NOjpDhjK7y1fBSii.bbwdUTRDOd7WFQWWieTXgUUr_qkJ8rvANnkvZuG0byNC6OwRNE0hHnOXxNruPFcPemhk75GY8OV0DxScYw_JaFpuHnp0vhF3xpozS3gKusa73aIkkKEArsokWt6Ua5CAUEpaAizXXOHO2qfM0GgmSmieTqigJaWem01ao1cTsasH4v0sBq2gkdcoKGaXvo45fjJdY3xc5TgyNqmvh4uA5yhUc5IiJRuDCTB6JmQiNzgSxka5J1ugGhMXo34OjhZSML8VX0WDnCvmb3imN_ChFNtJ5MkEdm1kDwg.0FDt4XVF7cw6nqJeMxC5YFQ.gm49BzwDCA.bfmey9KzYTfyTkKDUGy1CUhefhikJpDQvzibNcmy8H0fte2m6gEQt8eah91uffzUSMWL60VTLO_JLJVekZc7aQ'

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