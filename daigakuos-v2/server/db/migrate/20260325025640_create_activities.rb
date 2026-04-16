class CreateActivities < ActiveRecord::Migration[7.1]
  def change
    create_table :activities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :activity_type
      t.json :metadata

      t.timestamps
    end
  end
end
