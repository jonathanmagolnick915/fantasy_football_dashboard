class ProjectionsController < ApplicationController

  def index
    @projections = Projections.where(week).order("standard DESC")
  end

end
