class ValidationService
	# Variables
	# ...
	
	# Miscellaneous validation methods
	def self.validate_auth(auth)
		error_code = 1101
		return get_validation_hash(false, 2101, 401) if !auth

		api_key, signature = auth.split(',')
		dev = Dev.find_by(api_key: api_key)
		return get_validation_hash(false, error_code, 401) if !dev

		# Check the signature
		sig = Base64.strict_encode64(OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), dev.secret_key, dev.uuid))
		sig != signature ? get_validation_hash(false, error_code, 401) : get_validation_hash
	end

	def self.validate_app_belongs_to_dev(app, dev)
		error_code = 1102
		app.dev != dev ? get_validation_hash(false, error_code, 403) : get_validation_hash
	end

	def self.validate_dev_is_first_dev(dev)
		error_code = 1103
		dev != Dev.first ? get_validation_hash(false, error_code, 403) : get_validation_hash
	end

	def self.validate_content_type_json(content_type)
		error_code = 1104
		if content_type && content_type.include?("application/json")
			get_validation_hash
		else
			get_validation_hash(false, error_code, 415)
		end
	end

	def self.parse_json(json)
		json && json.length > 0 ? JSON.parse(json) : Hash.new
	rescue
		# Raise error for invalid body
		error_code = 1105
		raise RuntimeError, [get_validation_hash(false, error_code, 400)].to_json
	end

	# Methods for presence of fields
	def self.validate_auth_presence(auth)
		error_code = 2101
		!auth ? get_validation_hash(false, error_code, 401) : get_validation_hash
	end

	def self.validate_jwt_presence(jwt)
		error_code = 2102
		!jwt ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_email_presence(email)
		error_code = 2103
		!email ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_first_name_presence(first_name)
		error_code = 2104
		!first_name ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_password_presence(password)
		error_code = 2105
		!password ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_api_key_presence(api_key)
		error_code = 2106
		!api_key ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_device_name_presence(device_name)
		error_code = 2107
		!device_name ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_device_type_presence(device_type)
		error_code = 2108
		!device_type ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_device_os_presence(device_os)
		error_code = 2109
		!device_os ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	# Methods for type of fields
	def self.validate_email_type(email)
		error_code = 2201
		!email.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_first_name_type(first_name)
		error_code = 2202
		!first_name.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_password_type(password)
		error_code = 2203
		!password.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_app_id_type(app_id)
		error_code = 2204
		!app_id.is_a?(Integer) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_api_key_type(api_key)
		error_code = 2205
		!api_key.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_device_name_type(device_name)
		error_code = 2206
		!device_name.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_device_type_type(device_type)
		error_code = 2207
		!device_type.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_device_os_type(device_os)
		error_code = 2208
		!device_os.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	# Methods for validity of fields
	def self.validate_email_validity(email)
		error_code = 2401
		!validate_email(email) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	# Methods for availability of fields
	def self.validate_email_availability(email)
		error_code = 2701
		User.exists?(email: email) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	# Methods for existance of fields
	def self.validate_user_existance(user)
		error_code = 2801
		!user ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_dev_existance(dev)
		error_code = 2802
		!dev ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_app_existance(app)
		error_code = 2803
		!app ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	# Utility methods
	def self.validate_email(email)
		/[a-z0-9!#$%&'*+=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/.match?(email)
   end

	# Error methods
	def self.raise_validation_error(validation)
		if !validation[:success]
			raise RuntimeError, [validation].to_json
		end
	end

	def self.raise_multiple_validation_errors(validations)
		errors = Array.new
		validations.each do |validation|
			errors.push(validation) if !validation[:success]
		end

		if errors.length > 0
			raise RuntimeError, errors.to_json
		end
	end

	def self.get_errors_of_validations(validations)
		errors = Array.new
		validations.each do |validation|
			errors.push(validation["error"])
		end

		return errors
	end

	def self.get_validation_hash(success = true, error_code = 0, status_code = 200)
		if success
			{
				success: true
			}
		else
			{
				success: false,
				error: {code: error_code, message: get_error_message(error_code)},
				status: status_code
			}
		end
	end

	def self.get_error_message(code)
		case code
		when 1101
			"Unexpected error"
		when 1102
			"Authentication failed"
		when 1103
			"Action not allowed"
		when 1104
			"Content-Type not supported"
		when 1105
			"Invalid body"
		when 2101
			"Missing field: auth"
		when 2102
			"Missing field: jwt"
		when 2103
			"Missing field: email"
		when 2104
			"Missing field: first_name"
		when 2105
			"Missing field: password"
		when 2106
			"Missing field: api_key"
		when 2107
			"Missing field: device_name"
		when 2108
			"Missing field: device_type"
		when 2109
			"Missing field: device_os"
		when 2201
			"Field has wrong type: email"
		when 2202
			"Field has wrong type: first_name"
		when 2203
			"Field has wrong type: password"
		when 2204
			"Field has wrong type: app_id"
		when 2205
			"Field has wrong type: api_key"
		when 2206
			"Field has wrong type: device_name"
		when 2207
			"Field has wrong type: device_type"
		when 2208
			"Field has wrong type: device_os"
		when 2401
			"Field invalid: email"
		when 2701
			"Field already taken: email"
		when 2801
			"Resource does not exist: User"
		when 2802
			"Resource does not exist: Dev"
		when 2803
			"Resource does not exist: App"
		end
	end
end