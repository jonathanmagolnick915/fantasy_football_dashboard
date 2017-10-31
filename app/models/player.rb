class Player < ApplicationRecord
  # has_many :projections, order: 'week DESC'
  validates_uniqueness_of :yahoo_id

  def self.all_from_yahoo
    Yahoo.get_all_players.each do |data|
      player = Player.from_yahoo(data)
      player.set_lookup_key
      player.save
    end
    update_ffn_ids
  end

  def self.from_yahoo(data)
    player = Player.create(
        name:       "#{data[:first_name]} #{data[:last_name]}",
                first_name: data[:first_name],
                last_name:  data[:last_name],
                position:   data[:position],
                team:       data[:team],
                bye_week:   data[:bye_week].to_i,
                yahoo_id:   data[:yahoo_id],
                # yahoo_key:   data[:yahoo_key],
                team_id:    nil,
                active:     false
    )
  end

  def self.update_ffn_ids
    players = FFNerd.players
    players.each do |data|
      ffn_player = Player.from_ffn(data)
      yahoo_player = Player.find_by(lookup_key: ffn_player.lookup_key)
      unless yahoo_player.nil?
        yahoo_player.ffn_id = ffn_player.ffn_id
        yahoo_player.save
      end
    end
  end

  def self.from_ffn(data)
    player = Player.new(
        name:     data.display_name,
        position: data.position,
        ffn_id:   data.player_id,
        team:     data.team,
        # bye_week: data.bye,
        active: data.active,
        # TODO: update player key to include only the first two letters of the first name
        rotoworld_key: data.display_name.gsub(' ', '-').downcase
    )
    player.set_lookup_key
    player
  end

  def set_lookup_key
    #create a player key that will assist in the merging process
    #sometimes the first name is different - Stevie vs. Steve
    #so we just match on the first two letters
    # TODO: update player key to include only the first two letters of the first name
    temp_name = name.gsub(' ', '-').downcase
    if self.position == 'DEF'
      self.lookup_key = "#{team}-DEF"
    else
      self.lookup_key = "#{temp_name}-#{position}-#{team}"
    end
  end

  def self.merge(player1, player2)
    raise "Trying to merge different players" unless player1.lookup_key == player2.lookup_key
    player1.bye_week = player1.bye_week || player2.bye_week
    player1.yahoo_id = player1.yahoo_id || player2.yahoo_id
    player1.ffn_id   = player1.ffn_id   || player2.ffn_id
    player1.save
  end

  def set_rotoworld_key
    # TODO: update player key to include only the first two letters of the first name
  @rotoworld_key = name.gsub(' ', '-').downcase
  end

  def projection
    projection = projections.where(week: Projection.current_week).first
    projection.nil? ? "-" : projection.standard
  end

  def yahoo_team_name
    team_id.nil? ? '' : Team.find(team_id).name
  end

  def self.update_injuries
  end

  def self.reset_projections
    Player.update_all(points: 0)
  end

end