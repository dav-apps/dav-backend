class AddCountWeeklyToUserActivities < ActiveRecord::Migration[6.0]
  def change
	add_column :user_activities, :count_weekly, :integer, default: 0
  end
end
