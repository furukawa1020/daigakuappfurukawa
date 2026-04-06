class AddSharpnessToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :current_sharpness, :integer
    add_column :users, :max_sharpness, :integer
    add_column :users, :last_sharpened_at, :datetime
  end
end
