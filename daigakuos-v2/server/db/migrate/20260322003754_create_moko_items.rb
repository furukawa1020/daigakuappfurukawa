class CreateMokoItems < ActiveRecord::Migration[7.1]
  def change
    create_table :moko_items do |t|
      t.references :user, null: false, foreign_key: true
      t.string :item_id
      t.string :rarity
      t.datetime :unlocked_at

      t.timestamps
    end
  end
end
