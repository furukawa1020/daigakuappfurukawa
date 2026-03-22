class CreateReminders < ActiveRecord::Migration[7.1]
  def change
    create_table :reminders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :time
      t.string :message
      t.string :days_of_week
      t.boolean :is_active

      t.timestamps
    end
  end
end
