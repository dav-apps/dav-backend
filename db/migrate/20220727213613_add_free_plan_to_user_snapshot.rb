class AddFreePlanToUserSnapshot < ActiveRecord::Migration[6.1]
  def change
   add_column :user_snapshots, :free_plan, :integer, default: 0
  end
end
