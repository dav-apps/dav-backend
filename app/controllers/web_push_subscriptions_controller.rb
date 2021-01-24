class WebPushSubscriptionsController < ApplicationController
	def create_web_push_subscription
		access_token = get_auth

		ValidationService.raise_validation_error(ValidationService.validate_auth_header_presence(access_token))
		ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type))

		# Get the session
		session = ValidationService.get_session_from_token(access_token)

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		uuid = body["uuid"]
		endpoint = body["endpoint"]
		p256dh = body["p256dh"]
		auth = body["auth"]

		# Validate missing fields
		ValidationService.raise_multiple_validation_errors([
			ValidationService.validate_endpoint_presence(endpoint),
			ValidationService.validate_p256dh_presence(p256dh),
			ValidationService.validate_auth_presence(auth)
		])

		# Validate the types of the fields
		validations = Array.new
		validations.push(ValidationService.validate_uuid_type(uuid)) if !uuid.nil?
		validations.push(ValidationService.validate_endpoint_type(endpoint))
		validations.push(ValidationService.validate_p256dh_type(p256dh))
		validations.push(ValidationService.validate_auth_type(auth))
		ValidationService.raise_multiple_validation_errors(validations)

		# Validate the length of the fields
		ValidationService.raise_multiple_validation_errors([
			ValidationService.validate_endpoint_length(endpoint),
			ValidationService.validate_p256dh_length(p256dh),
			ValidationService.validate_auth_length(auth)
		])

		# Create the WebPushSubscription
		subscription = WebPushSubscription.new(
			session: session,
			endpoint: endpoint,
			p256dh: p256dh,
			auth: auth
		)

		if uuid.nil?
			subscription.uuid = SecureRandom.uuid
		else
			# Check if there is already a web push subscription with the uuid
			ValidationService.raise_validation_error(ValidationService.validate_web_push_subscription_uuid_availability(uuid))
			subscription.uuid = uuid
		end

		ValidationService.raise_unexpected_error(!subscription.save)

		# Return the data
		result = {
			id: subscription.id,
			session_id: subscription.session_id,
			uuid: subscription.uuid,
			endpoint: subscription.endpoint,
			p256dh: subscription.p256dh,
			auth: subscription.auth
		}
		render json: result, status: 201
	rescue RuntimeError => e
		validations = JSON.parse(e.message)
		render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.first["status"]
	end
end