class RenameCountYearlyOfAppUserSnapshotToYearlyActive < ActiveRecord::Migration[6.1]
  def change
   rename_column :app_user_snapshots, :count_yearly, :yearly_active
  end
end
