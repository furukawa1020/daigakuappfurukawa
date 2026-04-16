class AddMaterialsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :materials, :json
  end
end
