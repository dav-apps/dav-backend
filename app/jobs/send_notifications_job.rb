class SendNotificationsJob < ApplicationJob
	queue_as :default

	def perform(*args)
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
	end
end
