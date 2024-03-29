class ApiFunctionsController < ApplicationController
	def set_api_function
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
		name = body["name"]
		params = body["params"]
		commands = body["commands"]

		# Validate missing fields
		ValidationService.raise_validation_errors([
			ValidationService.validate_name_presence(name),
			ValidationService.validate_commands_presence(commands)
		])

		# Validate the types of the fields
		validations = Array.new
		validations.push(ValidationService.validate_name_type(name))
		validations.push(ValidationService.validate_params_type(params)) if !params.nil?
		validations.push(ValidationService.validate_commands_type(commands))
		ValidationService.raise_validation_errors(validations)

		# Validate the length of the fields
		validations = Array.new
		validations.push(ValidationService.validate_api_function_name_length(name))
		validations.push(ValidationService.validate_params_length(params)) if !params.nil?
		validations.push(ValidationService.validate_commands_length(commands))
		ValidationService.raise_validation_errors(validations)

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

		# Try to find the api function
		function = ApiFunction.find_by(api_slot: api_slot, name: name)

		if !function.nil?
			# Update the existing function
			function.params = params if !params.nil?
			function.commands = commands
		else
			# Create a new function
			function = ApiFunction.new(
				api_slot: api_slot,
				name: name,
				params: params.nil? ? "" : params,
				commands: commands
			)
		end

		ValidationService.raise_unexpected_error(!function.save)

		result = {
			id: function.id,
			api_slot_id: api_slot.id,
			name: function.name,
			params: function.params,
			commands: function.commands
		}
		render json: result, status: 200
	rescue RuntimeError => e
		render_errors(e)
	end
end