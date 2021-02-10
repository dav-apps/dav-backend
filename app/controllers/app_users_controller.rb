class AppUsersController < ApplicationController
	def get_app_users
		access_token = get_auth
		id = params[:id]

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
		app_users = Array.new
		AppUser.where(app_id: app.id).each do |app_user|
			app_users.push({
				user_id: app_user.user_id,
				created_at: app_user.created_at
			})
		end

		result = {
			app_users: app_users
		}

		render json: result, status: 200
	rescue RuntimeError => e
		render_errors(e)
	end
end