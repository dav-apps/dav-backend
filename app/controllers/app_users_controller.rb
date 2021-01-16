class AppUsersController < ApplicationController
	def get_app_users
		jwt, session_id = get_jwt
		id = params[:id]

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

		# Get the app
		app = App.find_by(id: id)
		ValidationService.raise_validation_error(ValidationService.validate_app_existence(app))

		# Make sure the app belongs to the dev of the user
		ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, user.dev))

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
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end
end