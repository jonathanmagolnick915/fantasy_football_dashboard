class Projection < ApplicationRecord
  POSITIONS = %w{QB RB WR TE K}

  def self.update_from_ffn
    week = current_week
    POSITIONS.each do |position|
      projections = FFNerd.weekly_rankings(position, week)
      projections.each do |projection|
        Projection.from_ffn(projection)
      end
    end
  end

  def self.from_ffn(projection)
    player = Player.find_by(ffn_id: projection[:player_id])
    unless player.nil?
      Projection.where(player_id: player.id).where(week: projection.week).delete_all
      Projection.create(
                    player_id: player.id,
          week: projection.week,
          standard: projection.standard.to_f,
          standard_low: projection.standard_low.to_f,
          standard_high: projection.standard_high.to_f,
          ppr: projection.ppr.to_f,
          ppr_low: projection.ppr_low.to_f,
          ppr_high: projection.ppr_high.to_f
      )
      player.points = projection.standard.to_f
      player.save
    end
  end

  def self.current_week
    #todo make this work for seasons post 2012-2013 season
    season_start_week = 36 #what week of the year does the season start? this correct for 2012
    week_of_year = Date.today.strftime('%W').to_i
    raise 'NFL is not in season' if week_of_year < season_start_week #week 52 is last week of season
    nfl_week = week_of_year - season_start_week + 1
    nfl_week -= 1 if Date.today.monday? #Monday should be last day of prev NFL week
    nfl_week
  end

end