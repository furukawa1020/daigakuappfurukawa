class AddVitalityToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :hp, :integer
    add_column :users, :max_hp, :integer
    add_column :users, :stamina, :integer
    add_column :users, :max_stamina, :integer
  end
end
