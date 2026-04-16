class CreateGlobalRaids < ActiveRecord::Migration[7.1]
  def change
    create_table :global_raids do |t|
      t.string :title
      t.integer :max_hp
      t.integer :current_hp
      t.string :status
      t.json :participants_data
      t.datetime :starts_at
      t.datetime :ends_at

      t.timestamps
    end
  end
end
