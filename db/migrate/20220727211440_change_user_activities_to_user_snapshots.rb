class ChangeUserActivitiesToUserSnapshots < ActiveRecord::Migration[6.1]
  def change
   rename_table :user_activities, :user_snapshots
  end
end
