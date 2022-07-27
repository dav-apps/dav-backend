class AddProPlanToAppUserSnapshot < ActiveRecord::Migration[6.1]
  def change
   add_column :app_user_snapshots, :pro_plan, :integer, default: 0
  end
end
