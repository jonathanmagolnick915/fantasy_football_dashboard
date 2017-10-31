class AddRowsToPlayers < ActiveRecord::Migration[5.1]
  def change
    add_column :players, :first_name, :string
    add_column :players, :last_name, :string
    add_column :players, :yahoo_key, :string
    add_column :players, :rotoworld_key, :string
    add_column :players, :rotoworld_id, :integer
    add_column :players, :lookup_key, :string
    add_column :players, :points, :float, :default => 0.0
  end
end
