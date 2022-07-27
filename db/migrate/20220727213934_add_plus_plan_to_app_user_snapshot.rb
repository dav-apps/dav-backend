class AddPlusPlanToAppUserSnapshot < ActiveRecord::Migration[6.1]
  def change
   add_column :app_user_snapshots, :plus_plan, :integer, default: 0
  end
end
