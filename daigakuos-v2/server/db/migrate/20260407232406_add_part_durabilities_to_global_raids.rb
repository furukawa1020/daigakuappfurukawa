class AddPartDurabilitiesToGlobalRaids < ActiveRecord::Migration[7.1]
  def change
    add_column :global_raids, :part_durabilities, :text
  end
end
