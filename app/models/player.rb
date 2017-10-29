class Player < ApplicationRecord



  def self.all_from_yahoo
    Yahoo::get_all_players.each do |data|
      Player.from_yahoo(data)
    end
    update_ffn_ids
  end


end
