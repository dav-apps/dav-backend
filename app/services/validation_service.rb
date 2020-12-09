class ValidationService
	# Variables
	first_name_min_length = 2
	first_name_max_length = 20
	password_min_length = 7
	password_max_length = 25
	device_name_min_length = 2
	device_name_max_length = 30
	device_type_min_length = 2
	device_type_max_length = 30
	device_os_min_length = 2
	device_os_max_length = 30
	
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
		app.dev != dev ? get_validation_hash(false, error_code, 403) : get_validation_hash
	end

	def self.validate_session_belongs_to_user(session, user)
		error_code = 1103
		session.user != user ? get_validation_hash(false, error_code, 403) : get_validation_hash
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

	def self.authenticate_user(user, password)
		error_code = 1201
		!user.authenticate(password) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_jwt(jwt, session_id)
		session = Session.find_by(id: session_id)
		return get_validation_hash(false, 2814, 404) if !session

		# Try to decode the jwt
		begin
			JWT.decode(jwt, session.secret, true, { algorithm: ENV["JWT_ALGORITHM"] })
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
		jwt.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
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

	# Methods for length of fields
	define_singleton_method :validate_first_name_length do |first_name|
		if first_name.length < first_name_min_length
			get_validation_hash(false, 2301, 400)
		elsif first_name.length > first_name_max_length
			get_validation_hash(false, 2401, 400)
		else
			get_validation_hash
		end
	end

	define_singleton_method :validate_password_length do |password|
		if password.length < password_min_length
			get_validation_hash(false, 2302, 400)
		elsif password.length > password_max_length
			get_validation_hash(false, 2402, 400)
		else
			get_validation_hash
		end
	end

	define_singleton_method :validate_device_name_length do |device_name|
		if device_name.length < device_name_min_length
			get_validation_hash(false, 2303, 400)
		elsif device_name.length > device_name_max_length
			get_validation_hash(false, 2403, 400)
		else
			get_validation_hash
		end
	end

	define_singleton_method :validate_device_type_length do |device_type|
		if device_type.length < device_type_min_length
			get_validation_hash(false, 2304, 400)
		elsif device_type.length > device_type_max_length
			get_validation_hash(false, 2404, 400)
		else
			get_validation_hash
		end
	end

	define_singleton_method :validate_device_os_length do |device_os|
		if device_os.length < device_os_min_length
			get_validation_hash(false, 2305, 400)
		elsif device_os.length > device_os_max_length
			get_validation_hash(false, 2405, 400)
		else
			get_validation_hash
		end
	end

	# Methods for validity of fields
	def self.validate_email_validity(email)
		error_code = 2501
		!validate_email(email) ? get_validation_hash(false, error_code, 400) : get_validation_hash
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

	def self.validate_session_existence(session)
		error_code = 2804
		session.nil? ? get_validation_hash(false, error_code, 404) : get_validation_hash
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
		when 2501
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