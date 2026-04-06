class AddLootToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :boss_archive, :text
    add_column :users, :passive_buffs, :text
  end
end
