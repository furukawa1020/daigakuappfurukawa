class AddMoodToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :moko_mood, :string
  end
end
