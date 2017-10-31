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
    request['authorization'] = 'Bearer NkMXWDXOsln0EvX5W3GDmP9p2F_vAptJh7hr16V9ie_XSJfYPlJBzJwpVdxoOaFNq513S6MVkRPI7.ppjc3k4jFcRy1FfVkzDdpxCpZ86VXliEgBfuVbD43T4JvED7rre6xiSHjxBcU_dHRoSnv6ACqgIWuBGO8_SkTPt5UyEjlwYFq9a1ldpgmZMHxKjSG6cpIlO8XgGznym41D4u0RLenqK.rqMbDKAQF45AX7lsBLFJN5kMA2rOf1KORje1lCoq.Ho28iuqsz.012eQmWhDyNa3uxevVQ6uf5bR7uA1OaEuNmFFKVTbPq5AkDDNpNE6FxcH1pqBys6dWXmn1hg1iZKrjPDTv9pgCyg1nNBwNGVghlSffkpC9TGaPhkax3BBdgMCxLp9DNxD778LmJttpfugBQ8FXjdcd4ulcRwRu1nx6rhF3i9eSOvydDLUSOMpy3gSAulLWU9d3.yOn32NWlbtORtoxtYfOevYkZa.1pHNs4M23rQ81dDi6rgdm0bqmbV9F9IuZGxPAH36TAAy45.mXcI1ll7znoCIDcndn.QqFzVo24sPZxksvxzEvvyl6qb6Gzi3Nh99OtJ7fsuvTGUrwTlR3W8Vsm4EUDiOSad3om3CXa3Kk0.j5y.v7c7CnhM45t6SK00A6C2HHuv.rvt7ND7uXJdOWHwY_RqOTaS2NOkrpKm8MJHZEemNhf6Rf3ScN_Xk.QOCWPhexiceAF5DzsRFU8RvxTylP6bF9x1AHPknWCjKWNkMeiPtCemUMNHvWZGyDmkbNg9u4lvzEr86mZuseXlLMxsBv5hHGkzPAJJFlFl_2Z1i8n70fJwU.Mwt2NmI_9CIcaeTSRj42igyDUW48jLDoG7cIwLmWTH_q_csPZ4LQSiY0ZTIHQ2DlyLlnxxFyuH6LYYR834oN1jRlicbhd._RRM8Kg2lVbKH_ZJRCsGwGckYJCPwj0Ld1ZidPXwxHLZ1mZa.TokD45uY_SBNJEVALWAMCLrtlZYhJITUC7AAaeE5uKfJQ6EVvy3p4rTkuFaI2r6Mkdh5XX2J2rGRgV6d9njKS7_LqPv4v070ONUs2EK3OhIoiQBHtqLNmMY1z29iRt'

    @response = Nokogiri::XML(http.request(request).body)
    @response
  end

  def self.get_league_metadata
    url = "#{LEAGUE_URL}/metadata"
    doc = get_xml(url)
    get_league_metadata_from_xml(doc)
  end


  def self.get_all_players(limit = 25)
    players_url = "#{LEAGUE_URL}/players"
    players = []

    (0..limit).step(25) do |i| #have to pull down in batches
      batch_url = "#{players_url};start=#{i};count=25"
      # batch_url = "#{players_url};start=1;count=5"
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