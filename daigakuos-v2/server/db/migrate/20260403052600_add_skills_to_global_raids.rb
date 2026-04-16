class AddSkillsToGlobalRaids < ActiveRecord::Migration[7.1]
  def change
    add_column :global_raids, :active_skill, :string
    add_column :global_raids, :skill_ends_at, :datetime
  end
end
