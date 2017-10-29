class CreateYahooFfs < ActiveRecord::Migration[5.1]
  def change
    create_table :yahoo_ffs do |t|
      t.string :access_token
      t.string :refresh_token

      t.timestamps
    end
  end
end
