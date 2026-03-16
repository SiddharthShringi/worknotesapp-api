class CreateWorkSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :work_sessions do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :project, null: false, foreign_key: true
      t.string :intent, null: false
      t.text :notes
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.timestamps
    end

    add_index :work_sessions, [ :user_id, :started_at ]
    add_index :work_sessions,
              :user_id,
              unique: true,
              where: "ended_at IS NULL",
              name: "index_one_active_session_per_user"

    add_check_constraint :work_sessions,
                          "ended_at IS NULL OR ended_at >= started_at",
                          name: "work_sessions_valid_time_range"
  end
end
