class UsersController < ApplicationController
	def signup
		auth = get_auth

		ValidationService.raise_validation_error(ValidationService.validate_auth_header_presence(auth))
		ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type))

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
		ValidationService.raise_multiple_validation_errors([
			ValidationService.validate_email_presence(email),
			ValidationService.validate_first_name_presence(first_name),
			ValidationService.validate_password_presence(password),
			ValidationService.validate_app_id_presence(app_id),
			ValidationService.validate_api_key_presence(dev_api_key)
		])

		# Validate the types of the fields
		validations = [
			ValidationService.validate_email_type(email),
			ValidationService.validate_first_name_type(first_name),
			ValidationService.validate_password_type(password),
			ValidationService.validate_app_id_type(app_id),
			ValidationService.validate_api_key_type(dev_api_key)
		]

		validations.push(ValidationService.validate_device_name_type(device_name)) if device_name != nil
		validations.push(ValidationService.validate_device_type_type(device_type)) if device_type != nil
		validations.push(ValidationService.validate_device_os_type(device_os)) if device_os != nil

		ValidationService.raise_multiple_validation_errors(validations)

		# Validate the length of the fields
		validations = [
			ValidationService.validate_first_name_length(first_name),
			ValidationService.validate_password_length(password)
		]

		validations.push(ValidationService.validate_device_name_length(device_name)) if device_name != nil
		validations.push(ValidationService.validate_device_type_length(device_type)) if device_type != nil
		validations.push(ValidationService.validate_device_os_length(device_os)) if device_os != nil

		ValidationService.raise_multiple_validation_errors(validations)

		# Validate the email
		ValidationService.raise_validation_error(ValidationService.validate_email_availability(email))
		ValidationService.raise_validation_error(ValidationService.validate_email_validity(email))

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

		# Create the user
		user = User.new(
			email: email,
			first_name: first_name,
			password: password,
			email_confirmation_token: generate_token
		)
		ValidationService.raise_unexpected_error(!user.save)
		
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

		UserNotifierMailer.email_confirmation(user).deliver_later

		result = {
			user: {
				id: user.id,
				email: user.email,
				first_name: user.first_name,
				confirmed: user.confirmed,
				plan: user.plan,
				total_storage: UtilsService.get_total_storage(user.plan, user.confirmed),
				used_storage: user.used_storage
			},
			jwt: jwt
		}

		if app_id != ENV["DAV_APPS_APP_ID"].to_i
			# If the session is for another app than the website, create another session for the website
			website_secret = SecureRandom.urlsafe_base64(30)

			website_session = Session.new(
				user: user,
				app: App.find_by(id: ENV["DAV_APPS_APP_ID"]),
				secret: website_secret,
				exp: Time.at(exp).utc,
				device_name: device_name,
				device_type: device_type,
				device_os: device_os
			)
			ValidationService.raise_unexpected_error(!website_session.save)

			website_payload = {user_id: user.id, app_id: ENV["DAV_APPS_APP_ID"], dev_id: 1, exp: exp}
			result["website_jwt"] = "#{JWT.encode(website_payload, website_secret, ENV['JWT_ALGORITHM'])}.#{website_session.id}"
		end

		render json: result, status: 201
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end

	def get_user
		jwt, session_id = get_jwt
		ValidationService.raise_validation_error(ValidationService.validate_jwt_presence(jwt))
		payload = ValidationService.validate_jwt(jwt, session_id)

		# Validate the user and dev
		user = User.find_by(id: payload[:user_id])
		ValidationService.raise_validation_error(ValidationService.validate_user_existence(user))

		dev = Dev.find_by(id: payload[:dev_id])
		ValidationService.raise_validation_error(ValidationService.validate_dev_existence(dev))

		is_website = payload[:app_id] == ENV["DAV_APPS_APP_ID"].to_i

		# Return the data
		result = {
			id: user.id,
			email: user.email,
			first_name: user.first_name,
			confirmed: user.confirmed,
			total_storage: UtilsService.get_total_storage(user.plan, user.confirmed),
			used_storage: user.used_storage
		}

		result[:stripe_customer_id] = user.stripe_customer_id if is_website
		result[:plan] = user.plan
		result[:subscription_status] = user.subscription_status if is_website
		result[:period_end] = user.period_end if is_website
		result[:dev] = !Dev.find_by(user: user).nil?
		result[:provider] = !Provider.find_by(user: user).nil?

		if is_website
			result[:apps] = Array.new

			# Get the apps of the user
			user.app_users.each do |app_user|
				app = app_user.app

				result[:apps].push({
					id: app.id,
					name: app.name,
					description: app.description,
					published: app.published,
					web_link: app.web_link,
					google_play_link: app.google_play_link,
					microsoft_store_link: app.microsoft_store_link,
					used_storage: app_user.used_storage
				})
			end
		end
		
		render json: result, status: 200
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end

	private
	def generate_token
      SecureRandom.hex(20)
   end
end