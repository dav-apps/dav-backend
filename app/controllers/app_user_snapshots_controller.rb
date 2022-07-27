class AppUserSnapshotsController < ApplicationController
	def get_app_user_snapshots
		access_token = get_auth
		id = params[:id]

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

		# Get the app
		app = App.find_by(id: id)
		ValidationService.raise_validation_errors(ValidationService.validate_app_existence(app))

		# Make sure the app belongs to the dev of the user
		ValidationService.raise_validation_errors(ValidationService.validate_app_belongs_to_dev(app, session.user.dev))

		# Collect and return the data
		snapshots = Array.new

		AppUserSnapshot.where("app_id = ? AND time >= ? AND time <= ?", app.id, start_timestamp, end_timestamp).each do |user_snapshot|
			snapshots.push({
				time: user_snapshot.time.to_s,
				daily_active: user_snapshot.daily_active,
				weekly_active: user_snapshot.weekly_active,
				monthly_active: user_snapshot.monthly_active,
				yearly_active: user_snapshot.yearly_active,
            free_plan: user_snapshot.free_plan,
            plus_plan: user_snapshot.plus_plan,
            pro_plan: user_snapshot.pro_plan
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