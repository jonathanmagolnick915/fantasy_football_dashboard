class AddColumnsToTeams < ActiveRecord::Migration[5.1]
  def change
    add_column :teams, :yahoo_id, :integer
    add_column :teams, :yahoo_key, :string
    add_column :teams, :yahoo_owner_id, :integer
    add_column :teams, :yahoo_owner_name, :string
    add_column :teams, :name, :string
  end
end
