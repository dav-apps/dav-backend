class NotificationsController < ApplicationController
	def create_notification
		access_token = get_auth

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))
		ValidationService.raise_validation_errors(ValidationService.validate_content_type_json(get_content_type))

		# Get the session
		session = ValidationService.get_session_from_token(access_token)

		# Get the params from the body
		request_body = ValidationService.parse_json(request.body.string)
		uuid = request_body["uuid"]
		time = request_body["time"]
		interval = request_body["interval"]
		title = request_body["title"]
		body = request_body["body"]

		# Validate missing fields
		ValidationService.raise_validation_errors([
			ValidationService.validate_time_presence(time),
			ValidationService.validate_interval_presence(interval),
			ValidationService.validate_title_presence(title),
			ValidationService.validate_body_presence(body)
		])

		# Validate the types of the fields
		validations = Array.new
		validations.push(ValidationService.validate_uuid_type(uuid)) if !uuid.nil?
		validations.push(ValidationService.validate_time_type(time))
		validations.push(ValidationService.validate_interval_type(interval))
		validations.push(ValidationService.validate_title_type(title))
		validations.push(ValidationService.validate_body_type(body))
		ValidationService.raise_validation_errors(validations)

		# Validate the length of the fields
		ValidationService.raise_validation_errors([
			ValidationService.validate_title_length(title),
			ValidationService.validate_body_length(body)
		])

		# Create the notification
		notification = Notification.new(
			user: session.user,
			app: session.app,
			time: Time.at(time),
			interval: interval,
			title: title,
			body: body
		)

		if uuid.nil?
			notification.uuid = SecureRandom.uuid
		else
			# Check if there is already a notification with the uuid
			ValidationService.raise_validation_errors(ValidationService.validate_notification_uuid_availability(uuid))
			notification.uuid = uuid
		end

		ValidationService.raise_unexpected_error(!notification.save)

		# Return the data
		result = {
			id: notification.id,
			user_id: notification.user_id,
			app_id: notification.app_id,
			uuid: notification.uuid,
			time: notification.time.to_i,
			interval: notification.interval,
			title: notification.title,
			body: notification.body
		}
		render json: result, status: 201
	rescue RuntimeError => e
		render_errors(e)
	end

	def get_notifications
		access_token = get_auth
		
		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))

		# Get the session
		session = ValidationService.get_session_from_token(access_token)

		# Get the notifications
		notifications = Array.new

		Notification.where(user: session.user, app: session.app).each do |notification|
			notifications.push({
				id: notification.id,
				user_id: notification.user_id,
				app_id: notification.app_id,
				uuid: notification.uuid,
				time: notification.time.to_i,
				interval: notification.interval,
				title: notification.title,
				body: notification.body
			})
		end

		# Return the data
		result = {
			notifications: notifications
		}
		render json: result, status: 200
	rescue RuntimeError => e
		render_errors(e)
	end

	def update_notification
		access_token = get_auth
		uuid = params[:uuid]

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))
		ValidationService.raise_validation_errors(ValidationService.validate_content_type_json(get_content_type))

		# Get the session
		session = ValidationService.get_session_from_token(access_token)

		# Get the params from the body
		request_body = ValidationService.parse_json(request.body.string)
		time = request_body["time"]
		interval = request_body["interval"]
		title = request_body["title"]
		body = request_body["body"]

		# Validate the types of the fields
		validations = Array.new
		validations.push(ValidationService.validate_time_type(time)) if !time.nil?
		validations.push(ValidationService.validate_interval_type(interval)) if !interval.nil?
		validations.push(ValidationService.validate_title_type(title)) if !title.nil?
		validations.push(ValidationService.validate_body_type(body)) if !body.nil?
		ValidationService.raise_validation_errors(validations)

		# Validate the length of the fields
		validations = Array.new
		validations.push(ValidationService.validate_title_length(title)) if !title.nil?
		validations.push(ValidationService.validate_body_length(body)) if !body.nil?
		ValidationService.raise_validation_errors(validations)

		# Get the notification
		notification = Notification.find_by(uuid: uuid)
		ValidationService.raise_validation_errors(ValidationService.validate_notification_existence(notification))
		ValidationService.raise_validation_errors(ValidationService.validate_notification_belongs_to_user(notification, session.user))
		ValidationService.raise_validation_errors(ValidationService.validate_notification_belongs_to_app(notification, session.app))

		# Update the attributes of the notification
		notification.time = Time.at(time) if !time.nil?
		notification.interval = interval if !interval.nil?
		notification.title = title if !title.nil?
		notification.body = body if !body.nil?
		ValidationService.raise_unexpected_error(!notification.save)

		# Return the data
		result = {
			id: notification.id,
			user_id: notification.user_id,
			app_id: notification.app_id,
			uuid: notification.uuid,
			time: notification.time.to_i,
			interval: notification.interval,
			title: notification.title,
			body: notification.body
		}
		render json: result, status: 200
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end

	def delete_notification
		access_token = get_auth
		uuid = params[:uuid]

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(access_token))

		# Get the session
		session = ValidationService.get_session_from_token(access_token)

		# Get the notification
		notification = Notification.find_by(uuid: uuid)
		ValidationService.raise_validation_errors(ValidationService.validate_notification_existence(notification))
		ValidationService.raise_validation_errors(ValidationService.validate_notification_belongs_to_user(notification, session.user))
		ValidationService.raise_validation_errors(ValidationService.validate_notification_belongs_to_app(notification, session.app))

		# Delete the notification
		notification.destroy!

		head 204, content_type: "application/json"
	rescue RuntimeError => e
		render_errors(e)
	end
end