class RenameCountMonthlyOfUserSnapshotToMonthlyActive < ActiveRecord::Migration[6.1]
  def change
   rename_column :user_snapshots, :count_monthly, :monthly_active
  end
end
