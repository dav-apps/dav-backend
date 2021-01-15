class UserActivitiesController < ApplicationController
	def get_user_activities
		jwt, session_id = get_jwt

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

		ValidationService.raise_validation_error(ValidationService.validate_auth_header_presence(jwt))
		payload = ValidationService.validate_jwt(jwt, session_id)

		# Validate the user and dev
		user = User.find_by(id: payload[:user_id])
		ValidationService.raise_validation_error(ValidationService.validate_user_existence(user))

		dev = Dev.find_by(id: payload[:dev_id])
		ValidationService.raise_validation_error(ValidationService.validate_dev_existence(dev))

		app = App.find_by(id: payload[:app_id])
		ValidationService.raise_validation_error(ValidationService.validate_app_existence(app))

		# Make sure this was called from the website
		ValidationService.raise_validation_error(ValidationService.validate_app_is_dav_app(app))

		# Make sure the user is the first dev
		ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(user.dev))

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