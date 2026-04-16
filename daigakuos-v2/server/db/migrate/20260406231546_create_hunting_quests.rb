class CreateHuntingQuests < ActiveRecord::Migration[7.1]
  def change
    create_table :hunting_quests do |t|
      t.string :target_monster
      t.integer :difficulty
      t.integer :required_minutes
      t.text :reward_pool
      t.string :status

      t.timestamps
    end
  end
end
