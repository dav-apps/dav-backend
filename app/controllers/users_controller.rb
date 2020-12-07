class UsersController < ApplicationController
	def signup
		auth = get_authorization_header

		ValidationService.raise_validation_error(ValidationService.validate_auth_presence(auth))
		ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		email = body["email"]
		first_name = body["first_name"]
		password = body["password"]
		app_id = body["app_id"]
		dev_api_key = body["api_key"]
		device_name = body["device_name"]
		device_type = body["device_type"]
		device_os = body["device_os"]

		# Validate missing fields
		validations = [
			ValidationService.validate_email_presence(email),
			ValidationService.validate_first_name_presence(first_name),
			ValidationService.validate_password_presence(password)
		]

		if app_id
			validations.push(
				ValidationService.validate_api_key_presence(dev_api_key),
				ValidationService.validate_device_name_presence(device_name),
				ValidationService.validate_device_type_presence(device_type),
				ValidationService.validate_device_os_presence(device_os)
			)
		end

		ValidationService.raise_multiple_validation_errors(validations)

		# Validate the types of the fields
		validations = [
			ValidationService.validate_email_type(email),
			ValidationService.validate_first_name_type(first_name),
			ValidationService.validate_password_type(password)
		]

		if app_id
			validations.push(
				ValidationService.validate_app_id_type(app_id),
				ValidationService.validate_api_key_type(dev_api_key),
				ValidationService.validate_device_name_type(device_name),
				ValidationService.validate_device_type_type(device_type),
				ValidationService.validate_device_os_type(device_os)
			)
		end

		ValidationService.raise_multiple_validation_errors(validations)

		# Get the dev
		dev = Dev.find_by(api_key: auth.split(',')[0])
		ValidationService.raise_validation_error(ValidationService.validate_dev_existance(dev))

		# Validate the auth
		ValidationService.raise_validation_error(ValidationService.validate_auth(auth))

		# Validate the dev
		ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

		if app_id
			# Get the app
			app = App.find_by(id: app_id)
			ValidationService.validate_app_existence(app)

			# Check if the app belongs to the dev with the api key
			app_dev = Dev.find_by(api_key: dev_api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_existance(app_dev))
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, app_dev))
		end

		# Validate the email
		ValidationService.raise_validation_error(ValidationService.validate_email_availability(email))
		ValidationService.raise_validation_error(ValidationService.validate_email_validity(email))

		# Validate the length of the fields
		validations = [
			ValidationService.validate_first_name_length(first_name),
			ValidationService.validate_password_length(password)
		]

		if app_id
			validations.push(
				ValidationService.validate_device_name_length(device_name),
				ValidationService.validate_device_type_length(device_type),
				ValidationService.validate_device_os_length(device_os)
			)
		end

		ValidationService.raise_multiple_validation_errors(validations)


		
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end
end