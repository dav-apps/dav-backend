class AddCountWeeklyToAppUserActivities < ActiveRecord::Migration[6.0]
  def change
	add_column :app_user_activities, :count_weekly, :integer, default: 0
  end
end
