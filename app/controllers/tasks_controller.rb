class TasksController < ApplicationController
	def create_user_activities
		# Create user activities for all apps
		create_user_activity(User.all, nil)

		# Create app user activities for each app
		App.all.each do |app|
			create_user_activity(AppUser.where(app: app), app)
		end

		head 204, content_type: "application/json"
	end

	def update_api_caches
		Api.all.each do |api|
			api.api_endpoints.where(caching: true).each do |api_endpoint|
				# Get the environment variables of the api
				env_vars = Hash.new
				api.api_env_vars.each do |env_var|
					env_vars[env_var.name] = UtilsService.convert_env_value(env_var.class_name, env_var.value)
				end

				api_endpoint.api_endpoint_request_caches.each do |cache|
					vars = Hash.new
					url_params = Hash.new
					vars["env"] = env_vars

					# Get the params
					cache.api_endpoint_request_cache_params.each do |param|
						url_params[param.name] = param.value
					end

					runner = DavExpressionRunner.new
					result = runner.run({
						api: api,
						vars: vars,
						commands: api_endpoint.commands,
						request: {
							headers: Hash.new,
							params: url_params,
							body: nil
						}
					})

					if result[:status] == 200 && !result[:file]
						# Update the cache
						cache.response = result[:data].to_json
						cache.save
					end
				end
			end
		end

		head 204, content_type: "application/json"
	end
	
	def send_notifications
		Notification.where("time <= ?", DateTime.now).each do |notification|
			if notification.title.nil? || notification.body.nil?
				# Delete the notification
				notification.destroy!
				next
			end

			# Send the notification to all web push subscriptions of the user
			message = JSON.generate({
				title: notification.title,
				body: notification.body
			})

			notification.user.sessions.each do |session|
				session.web_push_subscriptions.each do |web_push_subscription|
					begin
						Webpush.payload_send(
							message: message,
							endpoint: web_push_subscription.endpoint,
							p256dh: web_push_subscription.p256dh,
							auth: web_push_subscription.auth,
							vapid: {
								subject: "mailto:support@dav-apps.tech",
								public_key: ENV["WEBPUSH_PUBLIC_KEY"],
								private_key: ENV["WEBPUSH_PRIVATE_KEY"]
							}
						)
					rescue Webpush::InvalidSubscription, Webpush::ExpiredSubscription => e
						# Delete the web push subscription
						web_push_subscription.destroy!
					end
				end
			end

			if notification.interval > 0
				# Update the notification time
				notification.time = Time.at(notification.time.to_i + notification.interval)
				notification.save
			else
				notification.destroy!
			end
		end

		head 204, content_type: "application/json"
	end

	def delete_sessions
		# Delete sessions which were not used in the last 3 months
		Session.all.where("updated_at < ?", DateTime.now - 3.months).each do |session|
			session.destroy!
		end

		head 204, content_type: "application/json"
	end

	def delete_purchases
		# Delete not completed purchases which are older than one day
		Purchase.where(completed: false).where("created_at < ?", DateTime.now - 1.day).each do |purchase|
			# Delete the PaymentIntent
			Stripe::PaymentIntent.cancel(purchase.payment_intent_id)
			purchase.destroy!
		end

		head 204, content_type: "application/json"
	end

	private
	def create_user_activity(users, app)
		count_daily = 0
		count_monthly = 0
		count_yearly = 0

		users.each do |user|
			count_daily += 1 if user_was_active(user.last_active, 1.day)
			count_monthly += 1 if user_was_active(user.last_active, 1.month)
			count_yearly += 1 if user_was_active(user.last_active, 1.year)
		end

		if app.nil?
			UserActivity.create(
				time: DateTime.now.beginning_of_day,
				count_daily: count_daily,
				count_monthly: count_monthly,
				count_yearly: count_yearly
			)
		else
			AppUserActivity.create(
				app: app,
				time: DateTime.now.beginning_of_day,
				count_daily: count_daily,
				count_monthly: count_monthly,
				count_yearly: count_yearly
			)
		end
	end

	def user_was_active(last_active, timeframe)
		last_active.nil? ? false : Time.now - last_active < timeframe
	end
end