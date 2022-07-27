class AddFreePlanToAppUserSnapshot < ActiveRecord::Migration[6.1]
  def change
   add_column :app_user_snapshots, :free_plan, :integer, default: 0
  end
end
