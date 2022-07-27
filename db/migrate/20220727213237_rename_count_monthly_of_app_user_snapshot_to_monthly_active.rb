class RenameCountMonthlyOfAppUserSnapshotToMonthlyActive < ActiveRecord::Migration[6.1]
  def change
   rename_column :app_user_snapshots, :count_monthly, :monthly_active
  end
end
