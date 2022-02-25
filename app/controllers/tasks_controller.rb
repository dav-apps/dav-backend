class TasksController < ApplicationController
	def create_user_activities
		CreateUserActivitiesJob.perform_later
		head 204, content_type: "application/json"
	end

	def update_api_caches
		UpdateApiCachesJob.perform_later
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
end