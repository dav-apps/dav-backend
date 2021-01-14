class AppsController < ApplicationController
	def get_app
		jwt, session_id = get_jwt
		id = params["id"]

		ValidationService.raise_validation_error(ValidationService.validate_auth_header_presence(jwt))
		payload = ValidationService.validate_jwt(jwt, session_id)

		# Validate the payload data
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

		# Check if the app belongs to the dev of the user
		ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, user.dev))

		# Return the data
		result = {
			id: app.id,
			dev_id: app.dev_id,
			name: app.name,
			description: app.description,
			published: app.published,
			web_link: app.web_link,
			google_play_link: app.google_play_link,
			microsoft_store_link: app.microsoft_store_link
		}

		render json: result, status: 200
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end
end