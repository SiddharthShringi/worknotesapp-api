class BackfillWorkSessionDurations < ActiveRecord::Migration[8.0]
  def change
      execute <<~SQL
      UPDATE work_sessions
      SET duration = EXTRACT(EPOCH FROM (ended_at - started_at))::integer
      WHERE ended_at IS NOT NULL
        AND started_at IS NOT NULL;
    SQL
  end

  def down
    # No automatic reversal of the calculated durations.
  end
end
