class RenameCountDailyOfAppUserSnapshotToDailyActive < ActiveRecord::Migration[6.1]
  def change
   rename_column :app_user_snapshots, :count_daily, :daily_active
  end
end
