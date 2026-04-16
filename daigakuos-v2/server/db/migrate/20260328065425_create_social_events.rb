class CreateSocialEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :social_events do |t|
      t.references :user, null: false, foreign_key: true
      t.string :event_type
      t.json :metadata

      t.timestamps
    end
  end
end
