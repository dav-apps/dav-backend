class ChangeAppUserActivitiesToAppUserSnapshots < ActiveRecord::Migration[6.1]
  def change
   rename_table :app_user_activities, :app_user_snapshots
  end
end
