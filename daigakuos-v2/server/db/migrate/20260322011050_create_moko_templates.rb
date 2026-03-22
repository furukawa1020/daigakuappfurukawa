class CreateMokoTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :moko_templates do |t|
      t.string :code
      t.string :name
      t.string :description
      t.string :image_url
      t.integer :required_level
      t.integer :phase

      t.timestamps
    end
    add_index :moko_templates, :code
  end
end
