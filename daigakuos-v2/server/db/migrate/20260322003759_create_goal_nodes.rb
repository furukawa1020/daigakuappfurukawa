class CreateGoalNodes < ActiveRecord::Migration[7.1]
  def change
    create_table :goal_nodes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.string :node_type
      t.integer :estimate
      t.boolean :completed
      t.datetime :completed_at

      t.timestamps
    end
  end
end
