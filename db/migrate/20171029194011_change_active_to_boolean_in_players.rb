class ChangeActiveToBooleanInPlayers < ActiveRecord::Migration[5.1]
  def change
    change_column :players, :active, :boolean
  end
end
