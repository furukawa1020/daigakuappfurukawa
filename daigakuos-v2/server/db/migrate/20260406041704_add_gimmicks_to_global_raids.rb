class AddGimmicksToGlobalRaids < ActiveRecord::Migration[7.1]
  def change
    add_column :global_raids, :active_gimmick, :string
    add_column :global_raids, :gimmick_ends_at, :datetime
  end
end
