class SessionsController < ApplicationController
	def create_session
		auth = get_auth

		ValidationService.raise_validation_error(ValidationService.validate_auth_presence(auth))
		ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type))

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		email = body["email"]
		password = body["password"]
		app_id = body["app_id"]
		dev_api_key = body["api_key"]
		device_name = body["device_name"]
		device_type = body["device_type"]
		device_os = body["device_os"]

		# Validate missing fields
		ValidationService.raise_multiple_validation_errors([
			ValidationService.validate_email_presence(email),
			ValidationService.validate_password_presence(password),
			ValidationService.validate_app_id_presence(app_id),
			ValidationService.validate_api_key_presence(dev_api_key)
		])

		# Validate the types of the fields
		validations = [
			ValidationService.validate_email_type(email),
			ValidationService.validate_password_type(password),
			ValidationService.validate_app_id_type(app_id),
			ValidationService.validate_api_key_type(dev_api_key)
		]

		validations.push(ValidationService.validate_device_name_type(device_name)) if !device_name.nil?
		validations.push(ValidationService.validate_device_type_type(device_type)) if !device_type.nil?
		validations.push(ValidationService.validate_device_os_type(device_os)) if !device_os.nil?

		ValidationService.raise_multiple_validation_errors(validations)

		# Validate the length of the fields
		validations = []

		validations.push(ValidationService.validate_device_name_length(device_name)) if !device_name.nil?
		validations.push(ValidationService.validate_device_type_length(device_type)) if !device_type.nil?
		validations.push(ValidationService.validate_device_os_length(device_os)) if !device_os.nil?

		ValidationService.raise_multiple_validation_errors(validations)

		# Get the dev
		dev = Dev.find_by(api_key: auth.split(',')[0])
		ValidationService.raise_validation_error(ValidationService.validate_dev_existence(dev))

		# Validate the auth
		ValidationService.raise_validation_error(ValidationService.validate_auth(auth))

		# Validate the dev
		ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

		# Get the app
		app = App.find_by(id: app_id)
		ValidationService.raise_validation_error(ValidationService.validate_app_existence(app))

		# Check if the app belongs to the dev with the api key
		app_dev = Dev.find_by(api_key: dev_api_key)
		ValidationService.raise_validation_error(ValidationService.validate_dev_existence(app_dev))
		ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, app_dev))

		# Get and validate the user
		user = User.find_by(email: email)
		ValidationService.raise_validation_error(ValidationService.validate_user_existence(user))
		ValidationService.raise_validation_error(ValidationService.authenticate_user(user, password))

		# Create a session and generate the session jwt
		exp_hours = Rails.env.production? ? Constants::JWT_EXPIRATION_HOURS_PROD : Constants::JWT_EXPIRATION_HOURS_DEV
		exp = Time.now.to_i + exp_hours * 3600
		secret = SecureRandom.urlsafe_base64(30)

		session = Session.new(
			user: user,
			app: app,
			secret: secret,
			exp: Time.at(exp).utc,
			device_name: device_name,
			device_type: device_type,
			device_os: device_os
		)
		ValidationService.raise_unexpected_error(!session.save)

		payload = {user_id: user.id, app_id: app.id, dev_id: dev.id, exp: exp}
		jwt = "#{JWT.encode(payload, secret, ENV['JWT_ALGORITHM'])}.#{session.id}"
		
		result = {
			jwt: jwt
		}
		render json: result, status: 201
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end

	def delete_session
		jwt, session_id = get_jwt
		ValidationService.raise_validation_error(ValidationService.validate_jwt_presence(jwt))

		payload = ValidationService.validate_jwt(jwt, session_id)

		# Validate the user and dev
		user = User.find_by(id: payload[:user_id])
		ValidationService.raise_validation_error(ValidationService.validate_user_existence(user))

		dev = Dev.find_by(id: payload[:dev_id])
		ValidationService.raise_validation_error(ValidationService.validate_dev_existence(dev))

		# Get the session
		session = Session.find_by(id: session_id)
		ValidationService.raise_validation_error(ValidationService.validate_session_existence(session))

		# Delete the session
		session.destroy!

		head 204, content_type: "application/json"
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end
end