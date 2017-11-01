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
    request['authorization'] = 'Bearer lebyV97Osln_OifD73MXbVdUn0q6bMJ137O27ydi1vA8p075F9zvaRUoh4SjmiNs3Lqgy76ph0pz7b5Hqjq7RPjIfQZkELgi_BUzNdUtsEdC07gedswR295qSBrKy8eEjItcLss0yjRpo2avJ_s24jvvZKcSijAdw5.oFGuWoP3GLs2kjRvTALPw8GUgDsgxBHhdhyyRhIfmnuibzBaK7Bziw2pm5S5VW8HHKrlYyYfhBjQADtp1kQdIBNldcQqBhjlNxagJy_xjScDdU6FpaIwP6d_0yuUkaN1DMK25Mw5aXTKS12shW3eN.w_nonTdFSjfKSD5QOd2Ntm_7GrpNfMfFo9N0C3mmaLcOq_monngZn1n77z1TvJrRJBYqxhSgXqeTtgNVmFO6tHB1U7VGhNJK04Y9WLlb_gKPT2QZauBSGYMDCJ3A9k5wj2I911Q3gpRMFgxD5mhbUALjHIryGNTzHTaXsP.45XBacSE3Sx_JG8ehGTrNUDR5I_8bNGwvvgtGawmt801Cfjnz20d5nOYJVr4OloKp.YuFEVSxEKOlmyNTBGq.pCSntjcZPkRyrPYCa_17e7ZV9wYdm9bXEIsXGJL1yBiScrfRqR5V0mOlau4k1OArCka_bBWQIBij00jkOSmk8d81ZpfQyvJqiUIKsKTE561K1WXD4AgEqGL94Yu7zW21bH4tLMVUxodY5QZMMzASCBwG6_zmJDNZ1klDBGvrXPfCFXAHFb4WE6HWNSQeLjUUH_8FQhP31Zxz75eICXQnEkzq7SlmuUaUSml10aez8l37FKCqhr6PKtjcNzZ3EvbBcMRJorJt5P8_soE95sFhbw4JMKq1R04GP01qlarQ7B54800usj7j3.hrQ.TUbtmdzt9BBnMe06zV3OYqeS2e63t1PIwi12avXCJvweKxyYPx9spgN_FlOwIrJ2PtvY6NuB4OsQiyggsRuuDoKLVxPIfFtEjuet.C8Di_eJorHSx9UAQVaT.bm5ajEyHoEtPiBBgyymJmmwFe4_5mzlJ21h7ktmcghqwbP3L0TyxpoN5jSxAnqh8yRWD9QYcteiy7z4pkI3clKB8XfEF4H_RlDNk_ds-'

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