class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :set_layout_variables
  before_action :order_teams

  def set_layout_variables
    @all_teams = Team.all
    @league_name = Yahoo.get_league_metadata[:league_name]
  end

  def order_teams
    @ordered_teams = Team.sort_by_points
  end
end
