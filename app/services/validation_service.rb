class ValidationService
	# Miscellaneous validation methods
	def self.raise_unexpected_error(raise_error)
		if raise_error
			error_code = 1101
			raise RuntimeError, [get_validation_hash(false, error_code, 500)].to_json
		end
	end

	def self.validate_auth(auth)
		error_code = 1102
		return get_validation_hash(false, 2101, 401) if !auth

		api_key, signature = auth.split(',')
		dev = Dev.find_by(api_key: api_key)
		return get_validation_hash(false, error_code, 401) if !dev

		# Check the signature
		sig = Base64.strict_encode64(OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), dev.secret_key, dev.uuid))
		sig != signature ? get_validation_hash(false, error_code, 401) : get_validation_hash
	end

	def self.validate_app_belongs_to_dev(app, dev)
		error_code = 1103
		(app.nil? || dev.nil? || app.dev != dev) ? get_validation_hash(false, error_code, 403) : get_validation_hash
	end

	def self.validate_app_is_dav_app(app_id)
		error_code = 1103
		app_id.to_i != ENV["DAV_APPS_APP_ID"].to_i ? get_validation_hash(false, error_code, 403) : get_validation_hash
	end

	def self.validate_session_belongs_to_user(session, user)
		error_code = 1103
		session.user != user ? get_validation_hash(false, error_code, 403) : get_validation_hash
	end

	def self.validate_session_belongs_to_app(session, app)
		error_code = 1103
		session.app != app ? get_validation_hash(false, error_code, 403) : get_validation_hash
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
	rescue JSON::ParserError => e
		# Raise error for invalid body
		error_code = 1105
		raise RuntimeError, [get_validation_hash(false, error_code, 400)].to_json
	end

	def self.authenticate_user(user, password)
		error_code = 1201
		!user.authenticate(password) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_jwt(jwt, session_id)
		session = Session.find_by(id: session_id)
		raise RuntimeError, [get_validation_hash(false, 2805, 404)].to_json if session.nil?

		# Try to decode the jwt
		begin
			JWT.decode(jwt, session.secret, true, { algorithm: ENV["JWT_ALGORITHM"] })[0].transform_keys(&:to_sym)
		rescue JWT::ExpiredSignature
			raise RuntimeError, [get_validation_hash(false, 1301, 401)].to_json
		rescue JWT::DecodeError
			raise RuntimeError, [get_validation_hash(false, 1302, 401)].to_json
		rescue Exception
			raise RuntimeError, [get_validation_hash(false, 1303, 401)].to_json
		end
	end

	# Methods for presence of fields
	def self.validate_auth_presence(auth)
		error_code = 2101
		auth.nil? ? get_validation_hash(false, error_code, 401) : get_validation_hash
	end

	def self.validate_jwt_presence(jwt)
		error_code = 2102
		jwt.nil? ? get_validation_hash(false, error_code, 401) : get_validation_hash
	end

	def self.validate_email_presence(email)
		error_code = 2103
		email.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_first_name_presence(first_name)
		error_code = 2104
		first_name.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_password_presence(password)
		error_code = 2105
		password.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_app_id_presence(app_id)
		error_code = 2106
		app_id.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_api_key_presence(api_key)
		error_code = 2107
		api_key.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_name_presence(name)
		error_code = 2108
		name.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
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

	def self.validate_name_type(name)
		error_code = 2209
		!name.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	# Methods for length of fields
	def self.validate_first_name_length(first_name)
		if first_name.length < Constants::FIRST_NAME_MIN_LENGTH
			get_validation_hash(false, 2301, 400)
		elsif first_name.length > Constants::FIRST_NAME_MAX_LENGTH
			get_validation_hash(false, 2401, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_password_length(password)
		if password.length < Constants::PASSWORD_MIN_LENGTH
			get_validation_hash(false, 2302, 400)
		elsif password.length > Constants::PASSWORD_MAX_LENGTH
			get_validation_hash(false, 2402, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_device_name_length(device_name)
		if device_name.length < Constants::DEVICE_NAME_MIN_LENGTH
			get_validation_hash(false, 2303, 400)
		elsif device_name.length > Constants::DEVICE_NAME_MAX_LENGTH
			get_validation_hash(false, 2403, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_device_type_length(device_type)
		if device_type.length < Constants::DEVICE_TYPE_MIN_LENGTH
			get_validation_hash(false, 2304, 400)
		elsif device_type.length > Constants::DEVICE_TYPE_MAX_LENGTH
			get_validation_hash(false, 2404, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_device_os_length(device_os)
		if device_os.length < Constants::DEVICE_OS_MIN_LENGTH
			get_validation_hash(false, 2305, 400)
		elsif device_os.length > Constants::DEVICE_OS_MAX_LENGTH
			get_validation_hash(false, 2405, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_name_length(name)
		if name.length < Constants::NAME_MIN_LENGTH
			get_validation_hash(false, 2306, 400)
		elsif name.length > Constants::NAME_MAX_LENGTH
			get_validation_hash(false, 2406, 400)
		else
			get_validation_hash
		end
	end

	# Methods for validity of fields
	def self.validate_email_validity(email)
		error_code = 2501
		!validate_email(email) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_name_validity(name)
		error_code = 2502
		!validate_name(name) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	# Methods for availability of fields
	def self.validate_email_availability(email)
		error_code = 2701
		User.exists?(email: email) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	# Methods for existance of fields
	def self.validate_user_existence(user)
		error_code = 2801
		user.nil? ? get_validation_hash(false, error_code, 404) : get_validation_hash
	end

	def self.validate_dev_existence(dev)
		error_code = 2802
		dev.nil? ? get_validation_hash(false, error_code, 404) : get_validation_hash
	end

	def self.validate_app_existence(app)
		error_code = 2803
		app.nil? ? get_validation_hash(false, error_code, 404) : get_validation_hash
	end

	def self.validate_table_existence(table)
		error_code = 2804
		table.nil? ? get_validation_hash(false, error_code, 404) : get_validation_hash
	end

	def self.validate_session_existence(session)
		error_code = 2805
		session.nil? ? get_validation_hash(false, error_code, 404) : get_validation_hash
	end

	# Utility methods
	def self.validate_email(email)
		/[a-z0-9!#$%&'*+=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/.match?(email)
	end

	def self.validate_name(name)
		/^([A-Z]|[a-z])+$/.match?(name)
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
		when 1201
			"Password is incorrect"
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
			"Missing field: app_id"
		when 2107
			"Missing field: api_key"
		when 2108
			"Missing field: name"
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
		when 2209
			"Field has wrong type: name"
		when 2301
			"Field too short: first_name"
		when 2302
			"Field too short: password"
		when 2303
			"Field too short: device_name"
		when 2304
			"Field too short: device_type"
		when 2305
			"Field too short: device_os"
		when 2306
			"Field too short: name"
		when 2401
			"Field too long: first_name"
		when 2402
			"Field too long: password"
		when 2403
			"Field too long: device_name"
		when 2404
			"Field too long: device_type"
		when 2405
			"Field too long: device_os"
		when 2406
			"Field too long: name"
		when 2501
			"Field invalid: email"
		when 2502
			"Field invalid: name"
		when 2701
			"Field already taken: email"
		when 2801
			"Resource does not exist: User"
		when 2802
			"Resource does not exist: Dev"
		when 2803
			"Resource does not exist: App"
		when 2804
			"Resource does not exist: Table"
		when 2805
			"Resource does not exist: Session"
		end
	end
end