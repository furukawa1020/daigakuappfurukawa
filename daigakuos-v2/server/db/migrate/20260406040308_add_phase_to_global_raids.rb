class AddPhaseToGlobalRaids < ActiveRecord::Migration[7.1]
  def change
    add_column :global_raids, :current_phase, :integer
  end
end
