class AddSkillCooldownToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :last_skill_used_at, :datetime
  end
end
