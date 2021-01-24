class SessionsController < ApplicationController
	def create_session
		auth = get_auth

		ValidationService.raise_validation_error(ValidationService.validate_auth_header_presence(auth))
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

		# Create the session
		session = Session.new(
			user: user,
			app: app,
			token: Cuid::generate,
			device_name: device_name,
			device_type: device_type,
			device_os: device_os
		)
		ValidationService.raise_unexpected_error(!session.save)
		
		result = {
			access_token: session.token
		}
		render json: result, status: 201
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end

	def create_session_from_access_token
		auth = get_auth

		ValidationService.raise_validation_error(ValidationService.validate_auth_header_presence(auth))
		ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type))

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		access_token = body["access_token"]
		app_id = body["app_id"]
		api_key = body["api_key"]
		device_name = body["device_name"]
		device_type = body["device_type"]
		device_os = body["device_os"]

		# Validate missing fields
		ValidationService.raise_multiple_validation_errors([
			ValidationService.validate_access_token_presence(access_token),
			ValidationService.validate_app_id_presence(app_id),
			ValidationService.validate_api_key_presence(api_key)
		])

		# Validate the types of the fields
		validations = [
			ValidationService.validate_access_token_type(access_token),
			ValidationService.validate_app_id_type(app_id),
			ValidationService.validate_api_key_type(api_key)
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

		# Get the session
		website_session = ValidationService.get_session_from_token(access_token)

		# Make sure the session is for the website
		ValidationService.raise_validation_error(ValidationService.validate_app_is_dav_app(website_session.app))

		# Get the app
		app = App.find_by(id: app_id)
		ValidationService.raise_validation_error(ValidationService.validate_app_existence(app))

		# Check if the app belongs to the dev with the api key
		api_key_dev = Dev.find_by(api_key: api_key)
		ValidationService.raise_validation_error(ValidationService.validate_dev_existence(api_key_dev))
		ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, api_key_dev))

		# Create the session
		session = Session.new(
			user: website_session.user,
			app: app,
			token: Cuid::generate,
			device_name: device_name,
			device_type: device_type,
			device_os: device_os
		)
		ValidationService.raise_unexpected_error(!session.save)

		result = {
			access_token: session.token
		}
		render json: result, status: 201
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end

	def renew_session
		access_token = get_auth
		ValidationService.raise_validation_error(ValidationService.validate_auth_header_presence(access_token))

		# Get the session
		session = ValidationService.get_session_from_token(access_token, false)

		# Move the current token to old_token and generate a new token
		session.old_token = session.token
		session.token = Cuid.generate

		ValidationService.raise_unexpected_error(!session.save)

		# Return the new token
		result = {
			access_token: session.token
		}
		render json: result, status: 200
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end

	def delete_session
		access_token = get_auth
		ValidationService.raise_validation_error(ValidationService.validate_auth_header_presence(access_token))

		# Get the session
		session = ValidationService.get_session_from_token(access_token)

		# Delete the session
		session.destroy!

		head 204, content_type: "application/json"
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end
end