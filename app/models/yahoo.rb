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
    request['authorization'] = 'Bearer T4QjBC_OsllO_L.2rY7yy1el3eX.tBmDK7k5_XeU51pB__cHFaNlTJoIZ4fYVbvVpomIq9d_t2WwsF.1o4gs_XYAf9Gou8pM2kUprKKrm8omL1coxc_G.gx_fNY7jWa5TEWJwkB9ZdWanelRUy0H5Y9dgudVQAwvcJLm92w9b_g8dNkQBn6bHIRNMaxvAUwA0fjENlPdaySEtESAS54nKphAPFmVi15tvzOM2kMJ3TCWpyUlWHj4_hohDpwoIC.lH.yba8PcnhglIQdwhySOz8g0kKffQuWT5guaGlRXLd06ANL4bLq5hpnF6r0Be7zVkXW.Tppj9blMu1.fRib8NudjsK0txLts_8um.uip_wilHl9inBJqQqSkemx6sOrSGAfFxQgK1afnrl5JRSqJszZMduZPpBVWFILngt.EKp..B37qeS40L65ex81VXUl.wLAj0r4E3LjqrOBlYtOgd6dZ5NXCuCHRp1E3a4zyn0vE9snDgrcmVenfnn9vl68iFQ3qPfsQrVX3wHW8Mxiqjb1VimwB8nDRTpLA.nh0PmvoVD2d5wnVmQCQogF4U25WJUjGtW4Vt3Vm2CB8OHUFHkvaSfIeLmfZux651OxM0iV3eJh1ITGwGjJOpsx1s0KWugwgMuSJpmN5C3.VDC43rS0FPpj6qdo3WSl15LnRRBtw.rsKJXhL9fZQUY7.Cmz2ydfeigDoK.jkiepe8uLgHVUTU_hvS14.La4GYJYYzS9DS0YPWbTEp6Au9G_Tq1tWriD8s5E63vTOqltsfExW3Gsqv3ybNNBWfnQqOJ8Be_Itq309htXikbZsX0tNH5_nHTd9CoS2d9.Q3c6LsEL.Fz6qA7pPSvWdZs0U.xFFKgMfORaS_AG.MRC6VtC1kkOTG.0Y4Z0ezRnbGBorCP72h0KHD1XlUuzKiTsF0t4fatLlYwodIOqxrJypKzOTmcnCvN4SGIIfY4XHG2lgqhcUInZ0Hvv46sgtPKxZx3zwn4HhL_q2H86qE4qIkbQ53WUneklCc9sxzMGivZ6yyDnElGKvyTqFVRnZBftKwMDJA6UNnkTvsYD4RBNkbU9R7BsvzcLDtgGYmDs8hU5J'

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