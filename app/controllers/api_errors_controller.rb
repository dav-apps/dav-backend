class ApiErrorsController < ApplicationController
	def set_api_errors
		auth = get_auth
		api_id = params[:id]
		slot_name = params[:slot]

		ValidationService.raise_validation_errors(ValidationService.validate_auth_header_presence(auth))
		ValidationService.raise_validation_errors(ValidationService.validate_content_type_json(get_content_type))

		# Get the dev
		dev = Dev.find_by(api_key: auth.split(',')[0])
		ValidationService.raise_validation_errors(ValidationService.validate_dev_existence(dev))

		# Validate the auth
		ValidationService.raise_validation_errors(ValidationService.validate_auth(auth))

		# Get the params from the body
		body = ValidationService.parse_json(request.body.string)
		errors = body["errors"]

		# Validate missing fields
		ValidationService.raise_validation_errors(ValidationService.validate_errors_presence(errors))

		# Validate the types of the fields
		ValidationService.raise_validation_errors(ValidationService.validate_errors_type(errors))

		# Validate the errors
		errors.each do |error|
			ValidationService.raise_validation_errors([
				ValidationService.validate_code_type(error["code"]),
				ValidationService.validate_message_type(error["message"])
			])
		end

		errors.each do |error|
			ValidationService.raise_validation_errors(ValidationService.validate_message_length(error["message"]))
		end

		# Get the api
		api = Api.find_by(id: api_id)
		ValidationService.raise_validation_errors(ValidationService.validate_api_existence(api))

		# Check if the api belongs to an app of the dev
		ValidationService.raise_validation_errors(ValidationService.validate_app_belongs_to_dev(api.app, dev))

		# Get the api slot
		api_slot = api.api_slots.find_by(name: slot_name)

		if api_slot.nil?
			# Validate the slot name
			ValidationService.raise_validation_errors(ValidationService.validate_slot_length(slot_name))
			ValidationService.raise_validation_errors(ValidationService.validate_slot_validity(slot_name))

			# Create a slot with the name
			api_slot = ApiSlot.new(api: api, name: slot_name)
			ValidationService.raise_unexpected_error(!api_slot.save)
		end

		errors.each do |error|
			# Try to find the api error
			api_error = ApiError.find_by(api_slot: api_slot, code: error["code"])

			if !api_error.nil?
				# Update the existing error
				api_error.message = error["message"]
			else
				api_error = ApiError.new(
					api_slot: api_slot,
					code: error["code"],
					message: error["message"]
				)
			end

			ValidationService.raise_unexpected_error(!api_error.save)
		end

		head 204, content_type: "application/json"
	rescue RuntimeError => e
		render_errors(e)
	end
end