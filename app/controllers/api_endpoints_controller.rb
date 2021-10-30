class ApiEndpointsController < ApplicationController
	def set_api_endpoint
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
		path = body["path"]
		method = body["method"]
		commands = body["commands"]
		caching = body["caching"]

		# Validate missing fields
		ValidationService.raise_validation_errors([
			ValidationService.validate_path_presence(path),
			ValidationService.validate_method_presence(method),
			ValidationService.validate_commands_presence(commands)
		])

		# Validate the types of the fields
		validations = Array.new
		validations.push(ValidationService.validate_path_type(path))
		validations.push(ValidationService.validate_method_type(method))
		validations.push(ValidationService.validate_commands_type(commands))
		validations.push(ValidationService.validate_caching_type(caching)) if !caching.nil?
		ValidationService.raise_validation_errors(validations)

		# Validate the length of the fields
		ValidationService.raise_validation_errors([
			ValidationService.validate_path_length(path),
			ValidationService.validate_commands_length(commands)
		])

		# Check if the method is valid
		ValidationService.raise_validation_errors(ValidationService.validate_method_validity(method))

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

		# Try to find the api endpoint
		endpoint = ApiEndpoint.find_by(api_slot: api_slot, path: path, method: method.upcase)

		if !endpoint.nil?
			# Update the existing endpoint
			endpoint.commands = commands
			endpoint.caching = caching if !caching.nil?
		else
			# Create a new endpoint
			endpoint = ApiEndpoint.new(
				api_slot: api_slot,
				path: path,
				method: method.upcase,
				commands: commands
			)
			endpoint.caching = caching if !caching.nil?
		end

		ValidationService.raise_unexpected_error(!endpoint.save)

		result = {
			id: endpoint.id,
			api_slot_id: api_slot.id,
			path: endpoint.path,
			method: endpoint.method,
			commands: endpoint.commands,
			caching: endpoint.caching
		}
		render json: result, status: 200
	rescue RuntimeError => e
		render_errors(e)
	end
end