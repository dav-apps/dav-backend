class TasksController < ApplicationController
	def create_user_snapshots
		CreateUserSnapshotsJob.perform_later
		head 204, content_type: "application/json"
	end

	def send_notifications
		SendNotificationsJob.perform_later
		head 204, content_type: "application/json"
	end

	def delete_sessions
		DeleteSessionsJob.perform_later
		head 204, content_type: "application/json"
	end

	def delete_purchases
		DeletePurchasesJob.perform_later
		head 204, content_type: "application/json"
	end

	def update_redis_caches
		UpdateRedisCachesJob.perform_later
		head 204, content_type: "application/json"
	end
end