class ApiEnvVarsController < ApplicationController
	def set_api_env_vars
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
		env_vars = body["env_vars"]

		# Validate missing fields
		ValidationService.raise_validation_errors(ValidationService.validate_env_vars_presence(env_vars))

		# Validate the types of the fields
		ValidationService.raise_validation_errors(ValidationService.validate_env_vars_type(env_vars))

		# Validate the env vars
		env_vars.each do |key, value|
			ValidationService.raise_validation_errors([
				ValidationService.validate_env_var_name_type(key),
				ValidationService.validate_env_var_value_type(value)
			])
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

		env_vars.each do |key, value|
			class_name = UtilsService.get_env_class_name(value)
			if class_name.start_with?("array")
				value = value.join(',')
			else
				value = value.to_s
			end

			# Validate the length
			ValidationService.raise_validation_errors([
				ValidationService.validate_env_var_name_length(key),
				ValidationService.validate_env_var_value_length(value)
			])

			# Try to find the api env var
			env_var = ApiEnvVar.find_by(api_slot: api_slot, name: key)

			if !env_var.nil?
				# Update the existing env var
				env_var.value = value
				env_var.class_name = class_name
			else
				# Create a new env var
				env_var = ApiEnvVar.new(
					api_slot: api_slot,
					name: key,
					value: value,
					class_name: class_name
				)
			end

			ValidationService.raise_unexpected_error(!env_var.save)
		end

		head 204, content_type: "application/json"
	rescue RuntimeError => e
		render_errors(e)
	end
end