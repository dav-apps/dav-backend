class UsersController < ApplicationController
	def signup
		auth = get_auth

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(auth))
		ValidationService.raise_validation_errors(ValidationService.validate_content_type_json(get_content_type))

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		email = body["email"]
		first_name = body["first_name"]
		password = body["password"]
		app_id = body["app_id"]
		dev_api_key = body["api_key"]
		device_name = body["device_name"]
		device_os = body["device_os"]

		# Validate missing fields
		ValidationService.raise_validation_errors([
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
		validations.push(ValidationService.validate_device_os_type(device_os)) if device_os != nil

		ValidationService.raise_validation_errors(validations)

		# Validate the length of the fields
		validations = [
			ValidationService.validate_first_name_length(first_name),
			ValidationService.validate_password_length(password)
		]

		validations.push(ValidationService.validate_device_name_length(device_name)) if device_name != nil
		validations.push(ValidationService.validate_device_os_length(device_os)) if device_os != nil

		ValidationService.raise_validation_errors(validations)

		# Validate the email
		ValidationService.raise_validation_errors(ValidationService.validate_email_availability(email))
		ValidationService.raise_validation_errors(ValidationService.validate_email_validity(email))

		# Get the dev
		dev = Dev.find_by(api_key: auth.split(',')[0])
		ValidationService.raise_validation_errors(ValidationService.validate_dev_existence(dev))

		# Validate the auth
		ValidationService.raise_validation_errors(ValidationService.validate_auth(auth))

		# Validate the dev
		ValidationService.raise_validation_errors(ValidationService.validate_dev_is_first_dev(dev))

		# Get the app
		app = App.find_by(id: app_id)
		ValidationService.raise_validation_errors(ValidationService.validate_app_existence(app))

		# Check if the app belongs to the dev with the api key
		app_dev = Dev.find_by(api_key: dev_api_key)
		ValidationService.raise_validation_errors(ValidationService.validate_dev_existence(app_dev))
		ValidationService.raise_validation_errors(ValidationService.validate_app_belongs_to_dev(app, app_dev))

		# Create the user
		user = User.new(
			email: email,
			first_name: first_name,
			password: password,
			email_confirmation_token: generate_token
		)
		ValidationService.raise_unexpected_error(!user.save)

		# Create the session
		session = Session.new(
			user: user,
			app: app,
			token: Cuid.generate,
			device_name: device_name,
			device_os: device_os
		)
		ValidationService.raise_unexpected_error(!session.save)

		result = {
			user: {
				id: user.id,
				email: user.email,
				first_name: user.first_name,
				confirmed: user.confirmed,
				total_storage: UtilsService.get_total_storage(user.plan, user.confirmed),
				used_storage: user.used_storage,
				stripe_customer_id: user.stripe_customer_id,
				plan: user.plan,
				subscription_status: user.subscription_status,
				period_end: user.period_end,
				dev: false,
				provider: false,
				profile_image: "#{ENV['BASE_URL']}/user/#{user.id}/profile_image",
				profile_image_etag: Constants::DEFAULT_PROFILE_IMAGE_ETAG,
				apps: Array.new
			},
			access_token: session.token
		}

		if app_id != ENV["DAV_APPS_APP_ID"].to_i
			# If the session is for another app than the website, create a session for the website
			website_session = Session.new(
				user: user,
				app: App.find_by(id: ENV["DAV_APPS_APP_ID"]),
				token: Cuid.generate,
				device_name: device_name,
				device_os: device_os
			)
			ValidationService.raise_unexpected_error(!website_session.save)

			result["website_access_token"] = website_session.token
		end

		UserNotifierMailer.email_confirmation(user).deliver_later

		render json: result, status: 201
	rescue RuntimeError => e
		render_errors(e)
	end

	def get_user
		access_token = get_auth

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))

		# Get the session
		session = ValidationService.get_session_from_token(access_token)
		user = session.user
		is_website = session.app.id == ENV["DAV_APPS_APP_ID"].to_i

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
		result[:profile_image] = "#{ENV['BASE_URL']}/user/#{user.id}/profile_image"
		result[:profile_image_etag] = user.user_profile_image.nil? ? Constants::DEFAULT_PROFILE_IMAGE_ETAG : user.user_profile_image.etag

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
		render_errors(e)
	end

	def get_user_by_id
		auth = get_auth
		id = params[:id]

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(auth))

		# Get the dev
		dev = Dev.find_by(api_key: auth.split(',')[0])
		ValidationService.raise_validation_errors(ValidationService.validate_dev_existence(dev))

		# Validate the auth
		ValidationService.raise_validation_errors(ValidationService.validate_auth(auth))

		# Validate the dev
		ValidationService.raise_validation_errors(ValidationService.validate_dev_is_first_dev(dev))

		# Get the user
		user = User.find_by(id: id)
		ValidationService.raise_validation_errors(ValidationService.validate_user_existence(user))

		# Return the data
		result = {
			id: user.id,
			email: user.email,
			first_name: user.first_name,
			confirmed: user.confirmed,
			total_storage: UtilsService.get_total_storage(user.plan, user.confirmed),
			used_storage: user.used_storage,
			stripe_customer_id: user.stripe_customer_id,
			plan: user.plan,
			subscription_status: user.subscription_status,
			period_end: user.period_end,
			dev: !Dev.find_by(user: user).nil?,
			provider: !Provider.find_by(user: user).nil?,
			profile_image: "#{ENV['BASE_URL']}/user/#{user.id}/profile_image",
			profile_image_etag: user.user_profile_image.nil? ? Constants::DEFAULT_PROFILE_IMAGE_ETAG : user.user_profile_image.etag,
			apps: Array.new
		}

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

		render json: result, status: 200
	rescue RuntimeError => e
		render_errors(e)
	end

	def update_user
		access_token = get_auth

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))
		ValidationService.raise_validation_errors(ValidationService.validate_content_type_json(get_content_type))

		# Get the session
		session = ValidationService.get_session_from_token(access_token)
		user = session.user

		# Make sure this was called from the website
		ValidationService.raise_validation_errors(ValidationService.validate_app_is_dav_app(session.app))

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		email = body["email"]
		first_name = body["first_name"]
		password = body["password"]

		# Validate the types of the fields
		validations = Array.new
		validations.push(ValidationService.validate_email_type(email)) if !email.nil?
		validations.push(ValidationService.validate_first_name_type(first_name)) if !first_name.nil?
		validations.push(ValidationService.validate_password_type(password)) if !password.nil?
		ValidationService.raise_validation_errors(validations)

		# Validate the email
		ValidationService.raise_validation_errors(ValidationService.validate_email_availability(email))
		ValidationService.raise_validation_errors(ValidationService.validate_email_validity(email)) if !email.nil?

		# Validate the length of the fields
		validations = Array.new
		validations.push(ValidationService.validate_first_name_length(first_name)) if !first_name.nil?
		validations.push(ValidationService.validate_password_length(password)) if !password.nil?
		ValidationService.raise_validation_errors(validations)

		if !email.nil?
			user.new_email = email
			user.email_confirmation_token = generate_token
		end

		if !first_name.nil?
			user.first_name = first_name
		end

		if !password.nil?
			user.new_password = BCrypt::Password.create(password)
			user.password_confirmation_token = generate_token
		end

		ValidationService.raise_unexpected_error(!user.save)

		# Send the appropriate emails
		UserNotifierMailer.change_email(user).deliver_later if !email.nil?
		UserNotifierMailer.change_password(user).deliver_later if !password.nil?

		# Return the data
		result = {
			id: user.id,
			email: user.email,
			first_name: user.first_name,
			confirmed: user.confirmed,
			total_storage: UtilsService.get_total_storage(user.plan, user.confirmed),
			used_storage: user.used_storage,
			stripe_customer_id: user.stripe_customer_id,
			plan: user.plan,
			subscription_status: user.subscription_status,
			period_end: user.period_end,
			dev: !Dev.find_by(user: user).nil?,
			provider: !Provider.find_by(user: user).nil?,
			profile_image: "#{ENV['BASE_URL']}/user/#{user.id}/profile_image",
			profile_image_etag: user.user_profile_image.nil? ? Constants::DEFAULT_PROFILE_IMAGE_ETAG : user.user_profile_image.etag
		}

		render json: result, status: 200
	rescue RuntimeError => e
		render_errors(e)
	end

	def set_profile_image_of_user
		access_token = get_auth
		content_type = get_content_type

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))
		ValidationService.raise_validation_errors(ValidationService.validate_content_type_image(content_type))

		# Get the session
		session = ValidationService.get_session_from_token(access_token)
		user = session.user

		# Make sure this was called from the website
		ValidationService.raise_validation_errors(ValidationService.validate_app_is_dav_app(session.app))

		# Validate the file
		begin
			image = MiniMagick::Image.read(request.body)
		rescue => e
			ValidationService.raise_image_file_invalid
		end

		ValidationService.raise_validation_errors(ValidationService.validate_content_type_image(image.mime_type))

		# Validate the file size
		ValidationService.raise_validation_errors(ValidationService.validate_image_size(UtilsService.get_file_size(request.body)))

		# Get or create the UserProfileImage
		user_profile_image = user.user_profile_image
		user_profile_image = UserProfileImage.new(user: user) if user_profile_image.nil?

		# Upload the file
		begin
			upload_result = BlobOperationsService.upload_profile_image(user, request.body, image.mime_type)
		rescue => e
			ValidationService.raise_unexpected_error
		end

		etag = upload_result.etag

		user_profile_image.ext = image.type.downcase
		user_profile_image.mime_type = image.mime_type
		user_profile_image.etag = etag[1...etag.size - 1]

		ValidationService.raise_unexpected_error(!user_profile_image.save)

		# Return the data
		result = {
			id: user.id,
			email: user.email,
			first_name: user.first_name,
			confirmed: user.confirmed,
			total_storage: UtilsService.get_total_storage(user.plan, user.confirmed),
			used_storage: user.used_storage,
			stripe_customer_id: user.stripe_customer_id,
			plan: user.plan,
			subscription_status: user.subscription_status,
			period_end: user.period_end,
			dev: !Dev.find_by(user: user).nil?,
			provider: !Provider.find_by(user: user).nil?,
			profile_image: "#{ENV['BASE_URL']}/user/#{user.id}/profile_image",
			profile_image_etag: user_profile_image.etag
		}

		render json: result, status: 200
	rescue RuntimeError => e
		render_errors(e)
	end

	def get_profile_image_of_user
		access_token = get_auth
		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))

		# Get the session
		session = ValidationService.get_session_from_token(access_token)

		# Get the profile image
		user_profile_image = session.user.user_profile_image

		if !user_profile_image.nil?
			# Download the file
			begin
				blob, content = BlobOperationsService.download_profile_image(session.user)
				default_profile_image = false
			rescue => e
			end
		end

		# Download the default profile image
		if content.nil? || content.length == 0
			begin
				blob, content = BlobOperationsService.download_default_profile_image
				default_profile_image = true
			rescue => e
				ValidationService.raise_unexpected_error
			end
		end

		# Return the data
		response.headers["Content-Length"] = content.nil? ? 0 : content.size

		if default_profile_image
			send_data(content, status: 200, type: "image/png", filename: "default.png")
		else
			send_data(content, status: 200, type: user_profile_image.mime_type, filename: "#{session.user.id}.#{user_profile_image.ext}")
		end
	rescue RuntimeError => e
		render_errors(e)
	end

	def get_profile_image_of_user_by_id
		id = params[:id]

		# Get the user
		user = User.find_by(id: id)
		ValidationService.raise_validation_errors(ValidationService.validate_user_existence(user))

		# Get the profile image
		user_profile_image = user.user_profile_image

		if !user_profile_image.nil?
			# Download the file
			begin
				blob, content = BlobOperationsService.download_profile_image(user)
				default_profile_image = false
			rescue => e
			end
		end

		# Download the default profile image
		if content.nil? || content.length == 0
			begin
				blob, content = BlobOperationsService.download_default_profile_image
				default_profile_image = true
			rescue => e
				ValidationService.raise_unexpected_error
			end
		end

		# Return the data
		response.headers["Content-Length"] = content.nil? ? 0 : content.size

		if default_profile_image
			send_data(content, status: 200, type: "image/png", filename: "default.png")
		else
			send_data(content, status: 200, type: user_profile_image.mime_type, filename: "#{user.id}.#{user_profile_image.ext}")
		end
	rescue RuntimeError => e
		render_errors(e)
	end

	def create_stripe_customer_for_user
		access_token = get_auth
		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))

		# Get the session
		session = ValidationService.get_session_from_token(access_token)
		user = session.user

		# Make sure this was called from the website
		ValidationService.raise_validation_errors(ValidationService.validate_app_is_dav_app(session.app))

		# Check if the user already has a stripe customer
		ValidationService.raise_validation_errors(ValidationService.validate_user_has_no_stripe_customer(user))

		# Create the customer
		customer = Stripe::Customer.create(
			email: user.email
		)

		user.stripe_customer_id = customer.id
		ValidationService.raise_unexpected_error(!user.save)

		result = {
			stripe_customer_id: user.stripe_customer_id
		}

		render json: result, status: 201
	rescue RuntimeError => e
		render_errors(e)
	end

	def send_confirmation_email
		auth = get_auth
		id = params[:id]

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(auth))

		# Get the dev
		dev = Dev.find_by(api_key: auth.split(',')[0])
		ValidationService.raise_validation_errors(ValidationService.validate_dev_existence(dev))

		# Validate the auth
		ValidationService.raise_validation_errors(ValidationService.validate_auth(auth))

		# Validate the dev
		ValidationService.raise_validation_errors(ValidationService.validate_dev_is_first_dev(dev))

		# Get the user
		user = User.find_by(id: id)
		ValidationService.raise_validation_errors(ValidationService.validate_user_existence(user))

		# Generate the email confirmation token
		user.email_confirmation_token = generate_token
		ValidationService.raise_unexpected_error(!user.save)

		# Send the email
		UserNotifierMailer.email_confirmation(user).deliver_later

		head 204, content_type: "application/json"
	rescue RuntimeError => e
		render_errors(e)
	end

	def send_password_reset_email
		auth = get_auth

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(auth))
		ValidationService.raise_validation_errors(ValidationService.validate_content_type_json(get_content_type))

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		email = body["email"]

		# Validate missing fields
		ValidationService.raise_validation_errors(ValidationService.validate_email_presence(email))

		# Validate the types of the fields
		ValidationService.raise_validation_errors(ValidationService.validate_email_type(email))

		# Get the dev
		dev = Dev.find_by(api_key: auth.split(',')[0])
		ValidationService.raise_validation_errors(ValidationService.validate_dev_existence(dev))

		# Validate the auth
		ValidationService.raise_validation_errors(ValidationService.validate_auth(auth))

		# Validate the dev
		ValidationService.raise_validation_errors(ValidationService.validate_dev_is_first_dev(dev))

		# Get the user
		user = User.find_by(email: email)
		ValidationService.raise_validation_errors(ValidationService.validate_user_existence(user))

		# Generate the password confirmation token
		user.password_confirmation_token = generate_token
		ValidationService.raise_unexpected_error(!user.save)

		# Send the email
		UserNotifierMailer.password_reset(user).deliver_later

		head 204, content_type: "application/json"
	rescue RuntimeError => e
		render_errors(e)
	end

	def confirm_user
		auth = get_auth
		id = params[:id]

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(auth))
		ValidationService.raise_validation_errors(ValidationService.validate_content_type_json(get_content_type))

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		email_confirmation_token = body["email_confirmation_token"]

		# Validate the email_confirmation_token
		ValidationService.raise_validation_errors(ValidationService.validate_email_confirmation_token_presence(email_confirmation_token))
		ValidationService.raise_validation_errors(ValidationService.validate_email_confirmation_token_type(email_confirmation_token))

		# Get the dev
		dev = Dev.find_by(api_key: auth.split(',')[0])
		ValidationService.raise_validation_errors(ValidationService.validate_dev_existence(dev))

		# Validate the auth
		ValidationService.raise_validation_errors(ValidationService.validate_auth(auth))

		# Validate the dev
		ValidationService.raise_validation_errors(ValidationService.validate_dev_is_first_dev(dev))

		# Get the user
		user = User.find_by(id: id)
		ValidationService.raise_validation_errors(ValidationService.validate_user_existence(user))

		# Check if the user is already confirmed
		ValidationService.raise_validation_errors(ValidationService.validate_user_not_confirmed(user))

		# Check the confirmation token
		ValidationService.raise_validation_errors(ValidationService.validate_email_confirmation_token_of_user(user, email_confirmation_token))

		# Reset the email confirmation token and confirm the user
		user.email_confirmation_token = nil
		user.confirmed = true
		ValidationService.raise_unexpected_error(!user.save)

		head 204, content_type: "application/json"
	rescue RuntimeError => e
		render_errors(e)
	end

	def save_new_email
		auth = get_auth
		id = params[:id]

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(auth))
		ValidationService.raise_validation_errors(ValidationService.validate_content_type_json(get_content_type))

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		email_confirmation_token = body["email_confirmation_token"]

		# Validate the email confirmation token
		ValidationService.raise_validation_errors(ValidationService.validate_email_confirmation_token_presence(email_confirmation_token))
		ValidationService.raise_validation_errors(ValidationService.validate_email_confirmation_token_type(email_confirmation_token))

		# Get the dev
		dev = Dev.find_by(api_key: auth.split(',')[0])
		ValidationService.raise_validation_errors(ValidationService.validate_dev_existence(dev))

		# Validate the auth
		ValidationService.raise_validation_errors(ValidationService.validate_auth(auth))

		# Validate the dev
		ValidationService.raise_validation_errors(ValidationService.validate_dev_is_first_dev(dev))

		# Get the user
		user = User.find_by(id: id)
		ValidationService.raise_validation_errors(ValidationService.validate_user_existence(user))

		# Check if the user has a new email
		ValidationService.raise_validation_errors(ValidationService.validate_new_email_of_user_not_empty(user))

		# Check the confirmation token
		ValidationService.raise_validation_errors(ValidationService.validate_email_confirmation_token_of_user(user, email_confirmation_token))

		# Reset the email confirmation token and set the new email
		user.old_email = user.email
		user.email = user.new_email
		user.new_email = nil
		user.email_confirmation_token = generate_token

		ValidationService.raise_unexpected_error(!user.save)

		# Update the email of the Stripe customer
		update_stripe_customer_with_email(user)

		# Send email to reset the new email
		UserNotifierMailer.reset_email(user).deliver_later

		head 204, content_type: "application/json"
	rescue RuntimeError => e
		render_errors(e)
	end

	def save_new_password
		auth = get_auth
		id = params[:id]

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(auth))
		ValidationService.raise_validation_errors(ValidationService.validate_content_type_json(get_content_type))

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		password_confirmation_token = body["password_confirmation_token"]

		# Validate the password confirmation token
		ValidationService.raise_validation_errors(ValidationService.validate_password_confirmation_token_presence(password_confirmation_token))
		ValidationService.raise_validation_errors(ValidationService.validate_password_confirmation_token_type(password_confirmation_token))

		# Get the dev
		dev = Dev.find_by(api_key: auth.split(',')[0])
		ValidationService.raise_validation_errors(ValidationService.validate_dev_existence(dev))

		# Validate the auth
		ValidationService.raise_validation_errors(ValidationService.validate_auth(auth))

		# Validate the dev
		ValidationService.raise_validation_errors(ValidationService.validate_dev_is_first_dev(dev))

		# Get the user
		user = User.find_by(id: id)
		ValidationService.raise_validation_errors(ValidationService.validate_user_existence(user))

		# Check if the user has a new password
		ValidationService.raise_validation_errors(ValidationService.validate_new_password_of_user_not_empty(user))

		# Check the confirmation token
		ValidationService.raise_validation_errors(ValidationService.validate_password_confirmation_token_of_user(user, password_confirmation_token))

		# Reset the password confirmation token and set the new password
		user.password_digest = user.new_password
		user.new_password = nil
		user.password_confirmation_token = nil

		ValidationService.raise_unexpected_error(!user.save)

		head 204, content_type: "application/json"
	rescue RuntimeError => e
		render_errors(e)
	end

	def reset_email
		auth = get_auth
		id = params[:id]

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(auth))
		ValidationService.raise_validation_errors(ValidationService.validate_content_type_json(get_content_type))

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		email_confirmation_token = body["email_confirmation_token"]

		# Validate the email confirmation token
		ValidationService.raise_validation_errors(ValidationService.validate_email_confirmation_token_presence(email_confirmation_token))
		ValidationService.raise_validation_errors(ValidationService.validate_email_confirmation_token_type(email_confirmation_token))

		# Get the dev
		dev = Dev.find_by(api_key: auth.split(',')[0])
		ValidationService.raise_validation_errors(ValidationService.validate_dev_existence(dev))

		# Validate the auth
		ValidationService.raise_validation_errors(ValidationService.validate_auth(auth))

		# Validate the dev
		ValidationService.raise_validation_errors(ValidationService.validate_dev_is_first_dev(dev))

		# Get the user
		user = User.find_by(id: id)
		ValidationService.raise_validation_errors(ValidationService.validate_user_existence(user))

		# Check if the user has an old email
		ValidationService.raise_validation_errors(ValidationService.validate_old_email_of_user_not_empty(user))

		# Check the confirmation token
		ValidationService.raise_validation_errors(ValidationService.validate_email_confirmation_token_of_user(user, email_confirmation_token))

		# Reset the email and clear the email confirmation token
		user.email = user.old_email
		user.old_email = nil
		user.email_confirmation_token = nil

		ValidationService.raise_unexpected_error(!user.save)

		# Update the email of the Stripe customer
		update_stripe_customer_with_email(user)

		head 204, content_type: "application/json"
	rescue RuntimeError => e
		render_errors(e)
	end

	def set_password
		auth = get_auth
		id = params[:id]

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(auth))
		ValidationService.raise_validation_errors(ValidationService.validate_content_type_json(get_content_type))

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		password = body["password"]
		password_confirmation_token = body["password_confirmation_token"]

		# Validate missing fields
		ValidationService.raise_validation_errors([
			ValidationService.validate_password_presence(password),
			ValidationService.validate_password_confirmation_token_presence(password_confirmation_token)
		])

		# Validate the types of the fields
		ValidationService.raise_validation_errors([
			ValidationService.validate_password_type(password),
			ValidationService.validate_password_confirmation_token_type(password_confirmation_token)
		])

		# Validate the password length
		ValidationService.raise_validation_errors(ValidationService.validate_password_length(password))

		# Get the dev
		dev = Dev.find_by(api_key: auth.split(',')[0])
		ValidationService.raise_validation_errors(ValidationService.validate_dev_existence(dev))

		# Validate the auth
		ValidationService.raise_validation_errors(ValidationService.validate_auth(auth))

		# Validate the dev
		ValidationService.raise_validation_errors(ValidationService.validate_dev_is_first_dev(dev))

		# Get the user
		user = User.find_by(id: id)
		ValidationService.raise_validation_errors(ValidationService.validate_user_existence(user))

		# Check the confirmation token
		ValidationService.raise_validation_errors(ValidationService.validate_password_confirmation_token_of_user(user, password_confirmation_token))

		# Update the user with the new password and clear the password confirmation token
		user.password = password
		user.password_confirmation_token = nil

		ValidationService.raise_unexpected_error(!user.save)

		head 204, content_type: "application/json"
	rescue RuntimeError => e
		render_errors(e)
	end

	private
	def generate_token
      SecureRandom.hex(20)
	end
	
	def update_stripe_customer_with_email(user)
		return if user.stripe_customer_id.nil?

		customer = Stripe::Customer.retrieve(user.stripe_customer_id)
		return if customer.nil?

		customer.email = user.email
		customer.save
	rescue => e
		puts e
	end
end