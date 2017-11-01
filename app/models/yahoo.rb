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
    request['authorization'] = 'Bearer khBKZYvOsln5XoHk4MaWmf605YAeIXrogbsitCnynegTI6bBExqZRWXf8i3jQwt2ZfCYgwCBCKuT.S00GbApR7Ri8q9KtqS5ctC25zoCbemZCS_bME0ju_S2a0ZGi8XY4PbTOAi5TA1sCakNt_9dCKsLfzE4wrQeyNJLetglnssl7YItAULMptXCgURnArwfPyc6knop2mRWNJeIXDN2iP4Ckql6Avgnb_LIgsIlPySXGKS9sguPQTKqUjk5zZM9n9_pv.gSG.DkeNCzE_p7e9yNjHJ216XF8bpLSFRt2GTxCRlQXHFBitR_JKQ5G8O4wyChBJzB26HI_kSkIqjJCSC4RY4zggD002yAqeoX4xOnsr2h8KZV6OrL464G_68JNP4RZPu5ZN01zKif5.tOGvUnM7osbNPQNciV.MpBuznc926lBW4_DIlhMiyJIQyAe0IPCmyCxzu1g7HvTX2mEEGR1_ds_aPmcA0mKe.k1ShHAvlNz9YNW3bOfm3Iiqb.utbFF1_dl4x1S4nQ4rJTj6Ma1DXkVty1VsYjAJhJmxaIYlybOhfAQgG2JJEnifRymCG5akOj867Nu1XJOExoRSH04NZxbi5wlYDyl75LOOATRxhANdK1nC0ubbEyckyWOZERK.P9NhJet.4BVe9oRMXK8MhRdRIdDKwgP8wOsCVqJ3CgaCC7LMpjeUlJ6cU5ZQ4PuSlZyCxgRyAxspJDJeZzZ1TZsGXWw8gCtzDl5yw1VTz.c.SiiW70loIzS8_lg3A7zvIJhaXV6R0pHivpgLT6vMW3j.uRcQCh_i8xmckclyKyInUPTAOxUvkguyEa92kbvqGlfPDH1YLD39aygftOiP1Tsq41lP325nxyGz4GaHwTRJuHXzuhBwOuN6dVTmE7gmSpH1nUmPZxnnpJPGY_ArKdubpkTx5sqW9jZ9oXy_PNgeiDPJtjjxRfTIfv2DY661Dj26qyN8ZuHvdVs5IOHFcLYUWK1dRSxVSM3ZNlFGcqq_yQD7EOD2T5eMF7xywDI3aGpKR._mC0GFOJd8zAos89MS1e7BJBuEPEXQMlzh4ovZEhe5Nk77mfuqUE_6QCI6nHPbYy6wPj'

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