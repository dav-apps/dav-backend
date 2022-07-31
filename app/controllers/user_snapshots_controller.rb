class UserSnapshotsController < ApplicationController
	def get_user_snapshots
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

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))

		# Get the session
		session = ValidationService.get_session_from_token(access_token)

		# Make sure this was called from the website
		ValidationService.raise_validation_errors(ValidationService.validate_app_is_dav_app(session.app))

		# Make sure the user is the first dev
		ValidationService.raise_validation_errors(ValidationService.validate_dev_is_first_dev(session.user.dev))

		# Collect and return the data
		snapshots = Array.new

		UserSnapshot.where("time >= ? AND time <= ?", start_timestamp, end_timestamp).each do |user_snapshot|
			snapshots.push({
				time: user_snapshot.time.to_s,
				daily_active: user_snapshot.daily_active,
				weekly_active: user_snapshot.weekly_active,
				monthly_active: user_snapshot.monthly_active,
				yearly_active: user_snapshot.yearly_active,
            free_plan: user_snapshot.free_plan,
            plus_plan: user_snapshot.plus_plan,
            pro_plan: user_snapshot.pro_plan,
            email_confirmed: user_snapshot.email_confirmed,
            email_unconfirmed: user_snapshot.email_unconfirmed
			})
		end

		result = {
			snapshots: snapshots
		}

		render json: result, status: 200
	rescue RuntimeError => e
		render_errors(e)
	end
end