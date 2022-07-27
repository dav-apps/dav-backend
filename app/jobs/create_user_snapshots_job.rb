class CreateUserSnapshotsJob < ApplicationJob
	queue_as :default

	def perform(*args)
		# Create user snapshots for all apps
		create_user_snapshot(User.all, nil)

		# Create app user snapshots for each app
		App.all.each do |app|
			create_user_snapshot(AppUser.where(app: app), app)
		end
	end

	private
	def create_user_snapshot(users, app)
		daily_active = 0
		weekly_active = 0
		monthly_active = 0
		yearly_active = 0
      free_plan = 0
      plus_plan = 0
      pro_plan = 0

		users.each do |user|
			daily_active += 1 if user_was_active(user.last_active, 1.day)
			weekly_active += 1 if user_was_active(user.last_active, 1.week)
			monthly_active += 1 if user_was_active(user.last_active, 1.month)
			yearly_active += 1 if user_was_active(user.last_active, 1.year)

         case user.plan
         when 1
            plus_plan += 1
         when 2
            pro_plan += 1
         else
            free_plan += 1
         end
		end

		if app.nil?
			UserSnapshot.create(
				time: DateTime.now.beginning_of_day,
				daily_active: daily_active,
				weekly_active: weekly_active,
				monthly_active: monthly_active,
				yearly_active: yearly_active,
            free_plan: free_plan,
            plus_plan: plus_plan,
            pro_plan: pro_plan
			)
		else
			AppUserSnapshot.create(
				app: app,
				time: DateTime.now.beginning_of_day,
				daily_active: daily_active,
				weekly_active: weekly_active,
				monthly_active: monthly_active,
				yearly_active: yearly_active,
            free_plan: free_plan,
            plus_plan: plus_plan,
            pro_plan: pro_plan
			)
		end
	end

	def user_was_active(last_active, timeframe)
		last_active.nil? ? false : Time.now - last_active < timeframe
	end
end
