class WebsocketConnectionsController < ApplicationController
	def create_websocket_connection
		jwt, session_id = get_jwt

		ValidationService.raise_validation_error(ValidationService.validate_auth_header_presence(jwt))
		payload = ValidationService.validate_jwt(jwt, session_id)

		# Validate the user and dev
		user = User.find_by(id: payload[:user_id])
		ValidationService.raise_validation_error(ValidationService.validate_user_existence(user))

		dev = Dev.find_by(id: payload[:dev_id])
		ValidationService.raise_validation_error(ValidationService.validate_dev_existence(dev))

		app = App.find_by(id: payload[:app_id])
		ValidationService.raise_validation_error(ValidationService.validate_app_existence(app))

		# Create a WebsocketConnectionToken
		connection = WebsocketConnection.new(
			user: user,
			app: app,
			token: SecureRandom.hex(10)
		)
		ValidationService.raise_unexpected_error(!connection.save)

		# Return the data
		render json: {token: connection.token}, status: 201
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end
end