class WebsocketConnectionsController < ApplicationController
	def create_websocket_connection
		access_token = get_auth

		ValidationService.raise_validation_error(ValidationService.validate_auth_header_presence(access_token))

		# Get the session
		session = ValidationService.get_session_from_token(access_token)

		# Create a WebsocketConnectionToken
		connection = WebsocketConnection.new(
			user: session.user,
			app: session.app,
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