class AddPlusPlanToUserSnapshot < ActiveRecord::Migration[6.1]
  def change
   add_column :user_snapshots, :plus_plan, :integer, default: 0
  end
end
