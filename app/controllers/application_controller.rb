class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :set_layout_variables

  def set_layout_variables
    @all_teams = Team.all
    @league_name = Yahoo.get_league_metadata[:league_name]
  end
end
