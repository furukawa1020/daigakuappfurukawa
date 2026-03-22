class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :device_id
      t.integer :level
      t.integer :xp
      t.integer :streak
      t.integer :coins
      t.integer :rest_days
      t.datetime :last_sync_at

      t.timestamps
    end
    add_index :users, :device_id
  end
end
