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
    request['authorization'] = 'Bearer dBr0aU_OslncnDogq3FEhk5CcoOS9ByRKgVQlTjr9HjHLfkrTM_beecKWtVVU2fbLL3vC.u3v4lnx3J5s6u.LSdbKDbXbiJpxtbGoJ00mTfN47D35ROdeitRe_mKio68g2BrWes53tdhmlrk7JsKT7kS6h482uCDREcI5FjipkppAEIhYvItzzhG2El10CbZRmR230KkA35HUbB4fa4O3.CyqiPMu4xv.E9CObbsxyfKzwxfqygJ0SmGboO9USalzMa5XqTBLBNEpGTCQg05HtQfaD1mt2g2TbAxSA8ZTiYOfqIAJq7NAETbth7Qz14B4yPamKO5ozJJ1N4YYn8HIKCGcVzUrhUJA6KQcD69EwzlulFEi78VL2I3SNNh0Yz_AEATsOzaTy2eA6GcY710B_H..B5XwHL1yRG.BPFD0xRbuo.tVsNlAuIGDkYULgBkonhz7Y.ZpmIBcpb7xgRkpCfk02Zd_IBY2Y2YrFxWzpFIOk88ob5frqjIEm.CSzPj994z0q6MDUqhYgF0dqLDu6Sq66jH1szC_FGb5quNLqqxn6bpVZCiEFIUmsmAXvR24fPK22ZhPEDcZvR5FyIB2QW7YTkzYyToN7uvf22jhJ1zbxBSpKXbteK4BRWZ0Fp1QFaof3fM290jtnxz1ZOgWLYWL.iHCJbLFrc9DM47LW.pOgDFI7mI_in6hFRNRm5gdSf33Z1BMTYgiyWOyKhZgGamKIFvWsfdq8Qd7V2pTW.0fNXHEj1T_wOOuphHvAhzJyMDZuBAKg1wPIFbiUXjP4n7Xuto3zegAf0pPIbu7lh2coIhFgCPPUky.inlhqH4DC4G1sqef72MDyVfReiqqGuAnqEoS.i6gK3TKL6mRsadPGpDkAEe10M1kgo9IYUiMfZJ0.YsvdMT1dJWCBZ5UYPdGln8y2lRj4BCxmIzAyh5cKTC4K7GrLq8U17HlW91sjV429taj9Htk9zm6PlDxXmu51elEBvtA1bNqPvQqR60FVj3YEqSgJd3Ot15CFbcVlMx1wiDvVJu4kGyh5T9ckpk7COdZmH7jbit8a5Pv7Zf3g6FBxqS41hTiQggwmtw_lGBNLoL7ppzIM4W'

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