class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    enable_extension "citext"
    create_enum :project_color, [
      :blue, :green, :amber, :red, :violet,
      :cyan, :pink, :lime, :orange, :indigo,
      :teal, :rose ]
    create_table :projects do |t|
      t.citext :name, null: false
      t.text :description
      t.enum :color, enum_type: :project_color, null: false
      t.boolean :archived, default: false, null: false
      t.belongs_to :user, null: false, foreign_key: true
      t.timestamps
    end

    add_index :projects, [ :user_id, :name ], unique: true
  end
end
