class CreateUserActivitiesJob < ApplicationJob
	queue_as :default

	def perform(*args)
		# Create user activities for all apps
		create_user_activity(User.all, nil)

		# Create app user activities for each app
		App.all.each do |app|
			create_user_activity(AppUser.where(app: app), app)
		end
	end

	private
	def create_user_activity(users, app)
		count_daily = 0
		count_weekly = 0
		count_monthly = 0
		count_yearly = 0

		users.each do |user|
			count_daily += 1 if user_was_active(user.last_active, 1.day)
			count_weekly += 1 if user_was_active(user.last_active, 1.week)
			count_monthly += 1 if user_was_active(user.last_active, 1.month)
			count_yearly += 1 if user_was_active(user.last_active, 1.year)
		end

		if app.nil?
			UserActivity.create(
				time: DateTime.now.beginning_of_day,
				count_daily: count_daily,
				count_weekly: count_weekly,
				count_monthly: count_monthly,
				count_yearly: count_yearly
			)
		else
			AppUserActivity.create(
				app: app,
				time: DateTime.now.beginning_of_day,
				count_daily: count_daily,
				count_weekly: count_weekly,
				count_monthly: count_monthly,
				count_yearly: count_yearly
			)
		end
	end

	def user_was_active(last_active, timeframe)
		last_active.nil? ? false : Time.now - last_active < timeframe
	end
end
