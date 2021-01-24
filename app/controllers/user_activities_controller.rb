class UserActivitiesController < ApplicationController
	def get_user_activities
		access_token = get_auth

		if params[:start].nil?
			start_timestamp = (Time.now - 1.month).beginning_of_day
		else
			start_timestamp = Time.at(params[:start].to_i)
		end

		if params[:end].nil?
			end_timestamp = Time.now.beginning_of_day
		else
			end_timestamp = Time.at(params[:end].to_i)
		end

		ValidationService.raise_validation_error(ValidationService.validate_auth_header_presence(access_token))
		
		# Get the session
		session = ValidationService.get_session_from_token(access_token)

		# Make sure this was called from the website
		ValidationService.raise_validation_error(ValidationService.validate_app_is_dav_app(session.app))

		# Make sure the user is the first dev
		ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(session.user.dev))

		# Collect and return the data
		days = Array.new
		UserActivity.where("time >= ? AND time <= ?", start_timestamp, end_timestamp).each do |user_activity|
			days.push({
				time: user_activity.time.to_s,
				count_daily: user_activity.count_daily,
				count_monthly: user_activity.count_monthly,
				count_yearly: user_activity.count_yearly
			})
		end

		result = {
			days: days
		}

		render json: result, status: 200
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end
end