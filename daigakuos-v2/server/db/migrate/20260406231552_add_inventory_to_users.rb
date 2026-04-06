class AddInventoryToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :inventory, :text
  end
end
