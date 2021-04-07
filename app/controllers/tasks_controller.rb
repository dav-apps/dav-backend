class TasksController < ApplicationController
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
end