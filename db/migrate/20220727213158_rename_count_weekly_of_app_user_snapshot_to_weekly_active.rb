class RenameCountWeeklyOfAppUserSnapshotToWeeklyActive < ActiveRecord::Migration[6.1]
  def change
   rename_column :app_user_snapshots, :count_weekly, :weekly_active
  end
end
