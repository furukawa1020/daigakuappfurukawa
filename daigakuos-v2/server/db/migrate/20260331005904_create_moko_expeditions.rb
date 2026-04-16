class CreateMokoExpeditions < ActiveRecord::Migration[7.1]
  def change
    create_table :moko_expeditions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.integer :difficulty
      t.integer :required_focus_minutes
      t.float :progress
      t.string :status
      t.integer :monster_hp
      t.json :rewards

      t.timestamps
    end
  end
end
