class CreatePlayers < ActiveRecord::Migration[5.1]
  def change
    create_table :players do |t|
      t.string :name
      t.string :position
      t.string :team
      t.string :injury_status
      t.string :bye_week
      t.string :ffn_id
      t.string :yahoo_id
      t.integer :team_id
      t.boolean :active
      t.string :created_at
      t.string :updated_at

      t.timestamps
    end
  end
end
