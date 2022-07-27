class RenameCountYearlyOfUserSnapshotToYearlyActive < ActiveRecord::Migration[6.1]
  def change
   rename_column :user_snapshots, :count_yearly, :yearly_active
  end
end
