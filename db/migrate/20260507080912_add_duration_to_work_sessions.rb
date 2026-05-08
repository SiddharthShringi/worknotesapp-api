class AddDurationToWorkSessions < ActiveRecord::Migration[8.0]
  def up
    add_column :work_sessions, :duration, :integer

    execute <<~SQL
      UPDATE work_sessions
      SET duration = EXTRACT(EPOCH FROM (ended_at - started_at))
      WHERE started_at IS NOT NULL AND ended_at IS NOT NULL
    SQL

    change_column_null :work_sessions, :duration, false
    change_column_default :work_sessions, :duration, 0
    add_index :work_sessions, :started_at
  end

  def down
    remove_column :work_sessions, :duration
    remove_index :work_sessions, :started_at
  end
end
