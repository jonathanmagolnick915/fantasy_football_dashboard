desc "Daily maintenance"
task :update => :environment do
  Team.update_rosters
  Player.reset_projections
  Projection.update_from_ffn
end