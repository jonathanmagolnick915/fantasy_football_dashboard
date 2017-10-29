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
    request['authorization'] = 'Bearer BVLpjaHOsln0TEuheEQYZ1T1PjuV_M.GNuCx_3PYSrhuVgoveJGMfCFTZNn32HjBRio6TyQrjr_uTgccXv8ZhZzn8bWEykC82ob_IQOFDZn7g_pZh2U_kvZH6aZq_wtDGicnqGIEh8bWYLw7IkPn4fr8TrfAplzXAf_D8WLC4lwJB0pZdWHBTokGrr29ynVMRCfxe48_r.pT_iiSkd58Xzfn_JVSMW.6QTT4rTGFdRlltZ2VAWmsWNjlFgBnHfAUUKFh.fkWBwIUheq.qomTkuq4l9PvRLyC.hPLezD.dpwiWRUEIcM_gIAsjW0eDVbg_GYzuYzfqnCQ678nQJ80FWpU8.Sgflpa2kgeJuAb2UA_2fFVGm8SabCoZO8FgSKv5JbLwMTqXVOjDQPRi4d0OTUs3uGC.ZITDzCCOz9h4x88be2mRrYG5Xzl6QxZP8KGOpjQ5gGAlh41r1HwforfHiMnzhNDSOSnydXUBwFRmBbJoyEovsnrTBmRA0v9ae2PEJ9jHA_IdA.ZtPCp_WnjFP_q2c56bfI2rqB20RwouPe61zbpiaw1viep1JQvQQY4_gpLrM.7npir6ZyxuETdN8rG2p02zsHZf4w4n_bUKxDjNSzv1xdVDXjl.8us9xM8tOBE8C1miyXQT34OfmDXKtAd_5ZEO.qmS5V1TWsAKA1Y.mkhORBtzHTFegQUwhmiesXcDXkGAGps7Kd2nWr4ZLGaVPrwJkD.0x1SxXkU.PIUnRJv3gEPpd3pGfGSzzo9DoEh8VM4N7xFFSul0X6Lkh_5I_40tvMnHSj_loSA2NmZeJtpn86TmtHh0b1pW1wdw3POEZW7xm5tLm2e_6X6VSNBEZ8t..P4W6d6fs32BgFyTASQHPzrQi8dTWwO.xQLAvTfE2h2XCry5j.27y_F2jLpiuTpNOG9k5WlKjwidqWB7rAQT0BcpsFmoVnfvSb31y3muMyEEbpHlgnJIhgdiR_dfhE9nPCfGoPFTNrxG4K2tB_JOeozRhJDJZK5opuaBQdAER37z1FseZHO8L9kBI5LCJcPMP4JZhVNy7Edfhwv6d.1nb7rxU_XJ5nhbItowqsHST2WNeMTL3Ci'
    request['cache-control'] = 'no-cache'
    request['postman-token'] = '4e23a1cf-6da1-fac0-084c-f56bd30ff210'

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
    players     = []

    (0..limit).step(25) do |i| #have to pull down in batches
      batch_url = "#{players_url};start=#{i};count=25"
      doc = get_xml(batch_url)
      doc.css('players').each do |player_xml|
        players << get_player_hash_from_xml(player_xml)
      end
    end
  end

  def self.get_players_from_team(yahoo_team_key)
    players = []
    #http://developer.yahoo.com/fantasysports/guide/team-resource.html
    team_url = "#{BASE_URL}/team/#{yahoo_team_key}/roster"
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