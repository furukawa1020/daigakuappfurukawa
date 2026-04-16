class AddWhisperToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :whisper, :json
  end
end
