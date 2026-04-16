class AddPreparationToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :meal_buffs, :text
    add_column :users, :status_effects, :text
  end
end
