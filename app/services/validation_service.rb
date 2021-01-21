class ValidationService
	# Miscellaneous validation methods
	def self.raise_unexpected_error(raise_error = true)
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

	def self.validate_dev_is_first_dev(dev)
		error_code = 1103
		dev != Dev.first ? get_validation_hash(false, error_code, 403) : get_validation_hash
	end

	def self.validate_app_belongs_to_dev(app, dev)
		error_code = 1103
		(app.nil? || dev.nil? || app.dev != dev) ? get_validation_hash(false, error_code, 403) : get_validation_hash
	end

	def self.validate_app_is_dav_app(app)
		error_code = 1103
		app.id != ENV["DAV_APPS_APP_ID"].to_i ? get_validation_hash(false, error_code, 403) : get_validation_hash
	end

	def self.validate_table_belongs_to_app(table, app)
		error_code = 1103
		table.app != app ? get_validation_hash(false, error_code, 403) : get_validation_hash
	end

	def self.validate_table_object_belongs_to_user(table_object, user)
		error_code = 1103
		table_object.user != user ? get_validation_hash(false, error_code, 403) : get_validation_hash
	end

	def self.validate_table_object_belongs_to_app(table_object, app)
		error_code = 1103
		table_object.table.app != app ? get_validation_hash(false, error_code, 403) : get_validation_hash
	end

	def self.validate_notification_belongs_to_user(notification, user)
		error_code = 1103
		notification.user != user ? get_validation_hash(false, error_code, 403) : get_validation_hash
	end

	def self.validate_notification_belongs_to_app(notification, app)
		error_code = 1103
		notification.app != app ? get_validation_hash(false, error_code, 403) : get_validation_hash
	end

	def self.validate_content_type_json(content_type)
		return get_validation_hash(false, 1402, 400) if content_type.nil?
		return get_validation_hash(false, 1104, 415) if !content_type.include?("application/json")
		get_validation_hash
	end

	def self.validate_content_type_supported(content_type)
		return get_validation_hash(false, 1402, 400) if content_type.nil?
		return get_validation_hash(false, 1104, 415) if content_type.include?("application/x-www-form-urlencoded")
		get_validation_hash
	end

	def self.parse_json(json)
		json && json.length > 0 ? JSON.parse(json) : Hash.new
	rescue JSON::ParserError => e
		# Raise error for invalid body
		error_code = 1105
		raise RuntimeError, [get_validation_hash(false, error_code, 400)].to_json
	end

	def self.validate_table_object_is_file(table_object)
		error_code = 1106
		!table_object.file ? get_validation_hash(false, error_code, 422) : get_validation_hash
	end

	def self.raise_table_object_has_no_file
		error_code = 1107
		raise RuntimeError, [get_validation_hash(false, error_code, 404)].to_json
	end

	def self.validate_sufficient_storage(free_storage, file_size)
		error_code = 1108
		free_storage < file_size ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_user_not_confirmed(user)
		error_code = 1109
		user.confirmed ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.authenticate_user(user, password)
		error_code = 1201
		!user.authenticate(password) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_email_confirmation_token_of_user(user, email_confirmation_token)
		error_code = 1202
		user.email_confirmation_token != email_confirmation_token ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_password_confirmation_token_of_user(user, password_confirmation_token)
		error_code = 1203
		user.password_confirmation_token != password_confirmation_token ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_jwt(jwt, session_id)
		raise RuntimeError, [get_validation_hash(false, 1301, 401)].to_json if session_id == 0

		session = Session.find_by(id: session_id)
		raise RuntimeError, [get_validation_hash(false, 2806, 404)].to_json if session.nil?

		# Try to decode the jwt
		begin
			JWT.decode(jwt, session.secret, true, { algorithm: ENV["JWT_ALGORITHM"] })[0].transform_keys(&:to_sym)
		rescue JWT::DecodeError
			raise RuntimeError, [get_validation_hash(false, 1301, 401)].to_json
		rescue JWT::ExpiredSignature
			raise RuntimeError, [get_validation_hash(false, 1302, 401)].to_json
		rescue
			raise RuntimeError, [get_validation_hash(false, 1303, 401)].to_json
		end
	end

	# Methods for presence of headers
	def self.validate_auth_header_presence(auth)
		error_code = 1401
		auth.nil? ? get_validation_hash(false, error_code, 401) : get_validation_hash
	end

	# Methods for empty User attributes
	def self.validate_old_email_of_user_not_empty(user)
		error_code = 1501
		user.old_email.nil? ? get_validation_hash(false, error_code, 412) : get_validation_hash
	end

	def self.validate_new_email_of_user_not_empty(user)
		error_code = 1502
		user.new_email.nil? ? get_validation_hash(false, error_code, 412) : get_validation_hash
	end

	def self.validate_new_password_of_user_not_empty(user)
		error_code = 1503
		user.new_password.nil? ? get_validation_hash(false, error_code, 412) : get_validation_hash
	end

	# Methods for presence of fields
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

	def self.validate_name_presence(name)
		error_code = 2108
		name.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_table_id_presence(table_id)
		error_code = 2109
		table_id.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_properties_presence(properties)
		error_code = 2110
		properties.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_endpoint_presence(endpoint)
		error_code = 2111
		endpoint.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_p256dh_presence(p256dh)
		error_code = 2112
		p256dh.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end
	
	def self.validate_auth_presence(auth)
		error_code = 2113
		auth.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_time_presence(time)
		error_code = 2114
		time.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_interval_presence(interval)
		error_code = 2115
		interval.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_title_presence(title)
		error_code = 2116
		title.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_body_presence(body)
		error_code = 2117
		body.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_path_presence(path)
		error_code = 2118
		path.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_method_presence(method)
		error_code = 2119
		method.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_commands_presence(commands)
		error_code = 2120
		commands.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_errors_presence(errors)
		error_code = 2121
		errors.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_env_vars_presence(env_vars)
		error_code = 2122
		env_vars.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_description_presence(description)
		error_code = 2123
		description.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_email_confirmation_token_presence(email_confirmation_token)
		error_code = 2124
		email_confirmation_token.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_password_confirmation_token_presence(password_confirmation_token)
		error_code = 2125
		password_confirmation_token.nil? ? get_validation_hash(false, error_code, 400) : get_validation_hash
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

	def self.validate_uuid_type(uuid)
		error_code = 2210
		!uuid.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_table_id_type(table_id)
		error_code = 2211
		!table_id.is_a?(Integer) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_file_type(file)
		error_code = 2212
		(!file.is_a?(TrueClass) && !file.is_a?(FalseClass)) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_properties_type(properties)
		error_code = 2213
		!properties.is_a?(Hash) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_property_name_type(name)
		error_code = 2214
		!name.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_property_value_type(value)
		error_code = 2215
		return get_validation_hash if value.is_a?(NilClass)
		return get_validation_hash if value.is_a?(TrueClass)
		return get_validation_hash if value.is_a?(FalseClass)
		return get_validation_hash if value.is_a?(String)
		return get_validation_hash if value.is_a?(Integer)
		return get_validation_hash if value.is_a?(Float)
		get_validation_hash(false, error_code, 400)
	end

	def self.validate_ext_type(ext)
		error_code = 2216
		!ext.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_table_alias_type(table_alias)
		error_code = 2217
		!table_alias.is_a?(Integer) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_endpoint_type(endpoint)
		error_code = 2218
		!endpoint.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_p256dh_type(p256dh)
		error_code = 2219
		!p256dh.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_auth_type(auth)
		error_code = 2220
		!auth.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_time_type(time)
		error_code = 2221
		!time.is_a?(Integer) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_interval_type(interval)
		error_code = 2222
		!interval.is_a?(Integer) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_title_type(title)
		error_code = 2223
		!title.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_body_type(body)
		error_code = 2224
		!body.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_path_type(path)
		error_code = 2225
		!path.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_method_type(method)
		error_code = 2226
		!method.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_commands_type(commands)
		error_code = 2227
		!commands.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_caching_type(caching)
		error_code = 2228
		(!caching.is_a?(TrueClass) && !caching.is_a?(FalseClass)) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_params_type(params)
		error_code = 2229
		!params.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_errors_type(errors)
		error_code = 2230
		!errors.is_a?(Array) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_code_type(code)
		error_code = 2231
		!code.is_a?(Integer) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_message_type(message)
		error_code = 2232
		!message.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_env_vars_type(env_vars)
		error_code = 2233
		!env_vars.is_a?(Hash) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_value_type(value)
		error_code = 2234
		return get_validation_hash if value.is_a?(TrueClass)
		return get_validation_hash if value.is_a?(FalseClass)
		return get_validation_hash if value.is_a?(String)
		return get_validation_hash if value.is_a?(Integer)
		return get_validation_hash if value.is_a?(Float)
		return get_validation_hash if value.is_a?(Array)
		get_validation_hash(false, error_code, 400)
	end

	def self.validate_jwt_type(jwt)
		error_code = 2235
		!jwt.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_description_type(description)
		error_code = 2236
		!description.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_published_type(published)
		error_code = 2237
		(!published.is_a?(TrueClass) && !published.is_a?(FalseClass)) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_web_link_type(web_link)
		error_code = 2238
		!web_link.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_google_play_link_type(google_play_link)
		error_code = 2239
		!google_play_link.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_microsoft_store_link_type(microsoft_store_link)
		error_code = 2240
		!microsoft_store_link.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_email_confirmation_token_type(email_confirmation_token)
		error_code = 2241
		!email_confirmation_token.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_password_confirmation_token_type(password_confirmation_token)
		error_code = 2242
		!password_confirmation_token.is_a?(String) ? get_validation_hash(false, error_code, 400) : get_validation_hash
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

	def self.validate_api_function_name_length(name)
		if name.length < Constants::API_FUNCTION_NAME_MIN_LENGTH
			get_validation_hash(false, 2306, 400)
		elsif name.length > Constants::API_FUNCTION_NAME_MAX_LENGTH
			get_validation_hash(false, 2406, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_property_name_length(name)
		if name.length < Constants::PROPERTY_NAME_MIN_LENGTH
			get_validation_hash(false, 2307, 400)
		elsif name.length > Constants::PROPERTY_NAME_MAX_LENGTH
			get_validation_hash(false, 2407, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_property_value_length(value)
		return get_validation_hash if !value.is_a?(String)

		if value.length < Constants::PROPERTY_VALUE_MIN_LENGTH
			get_validation_hash(false, 2308, 400)
		elsif value.length > Constants::PROPERTY_VALUE_MAX_LENGTH
			get_validation_hash(false, 2408, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_ext_length(ext)
		if ext.length < Constants::EXT_MIN_LENGTH
			get_validation_hash(false, 2309, 400)
		elsif ext.length > Constants::EXT_MAX_LENGTH
			get_validation_hash(false, 2409, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_endpoint_length(endpoint)
		if endpoint.length < Constants::ENDPOINT_MIN_LENGTH
			get_validation_hash(false, 2310, 400)
		elsif endpoint.length > Constants::ENDPOINT_MAX_LENGTH
			get_validation_hash(false, 2410, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_p256dh_length(p256dh)
		if p256dh.length < Constants::P256DH_MIN_LENGTH
			get_validation_hash(false, 2311, 400)
		elsif p256dh.length > Constants::P256DH_MAX_LENGTH
			get_validation_hash(false, 2411, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_auth_length(auth)
		if auth.length < Constants::AUTH_MIN_LENGTH
			get_validation_hash(false, 2312, 400)
		elsif auth.length > Constants::AUTH_MAX_LENGTH
			get_validation_hash(false, 2412, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_title_length(title)
		if title.length < Constants::TITLE_MIN_LENGTH
			get_validation_hash(false, 2313, 400)
		elsif title.length > Constants::TITLE_MAX_LENGTH
			get_validation_hash(false, 2413, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_body_length(body)
		if body.length < Constants::BODY_MIN_LENGTH
			get_validation_hash(false, 2314, 400)
		elsif body.length > Constants::BODY_MAX_LENGTH
			get_validation_hash(false, 2414, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_path_length(path)
		if path.length < Constants::PATH_MIN_LENGTH
			get_validation_hash(false, 2315, 400)
		elsif path.length > Constants::PATH_MAX_LENGTH
			get_validation_hash(false, 2415, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_commands_length(commands)
		if commands.length < Constants::COMMANDS_MIN_LENGTH
			get_validation_hash(false, 2316, 400)
		elsif commands.length > Constants::COMMANDS_MAX_LENGTH
			get_validation_hash(false, 2416, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_params_length(params)
		if params.length < Constants::PARAMS_MIN_LENGTH
			get_validation_hash(false, 2317, 400)
		elsif params.length > Constants::PARAMS_MAX_LENGTH
			get_validation_hash(false, 2417, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_message_length(message)
		if message.length < Constants::MESSAGE_MIN_LENGTH
			get_validation_hash(false, 2318, 400)
		elsif message.length > Constants::MESSAGE_MAX_LENGTH
			get_validation_hash(false, 2418, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_api_env_var_value_length(value)
		if value.length < Constants::API_ENV_VAR_VALUE_MIN_LENGTH
			get_validation_hash(false, 2319, 400)
		elsif value.length > Constants::API_ENV_VAR_VALUE_MAX_LENGTH
			get_validation_hash(false, 2419, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_description_length(description)
		if description.length < Constants::DESCRIPTION_MIN_LENGTH
			get_validation_hash(false, 2320, 400)
		elsif description.length > Constants::DESCRIPTiON_MAX_LENGTH
			get_validation_hash(false, 2420, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_web_link_length(web_link)
		if web_link.length < Constants::WEB_LINK_MIN_LENGTH
			get_validation_hash(false, 2321, 400)
		elsif web_link.length > Constants::WEB_LINK_MAX_LENGTH
			get_validation_hash(false, 2421, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_google_play_link_length(google_play_link)
		if google_play_link.length < Constants::GOOGLE_PLAY_LINK_MIN_LENGTH
			get_validation_hash(false, 2322, 400)
		elsif google_play_link.length > Constants::GOOGLE_PLAY_LINK_MAX_LENGTH
			get_validation_hash(false, 2422, 400)
		else
			get_validation_hash
		end
	end

	def self.validate_microsoft_store_link_length(microsoft_store_link)
		if microsoft_store_link.length < Constants::MICROSOFT_STORE_LINK_MIN_LENGTH
			get_validation_hash(false, 2323, 400)
		elsif microsoft_store_link.length > Constants::MICROSOFT_STORE_LINK_MAX_LENGTH
			get_validation_hash(false, 2423, 400)
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

	def self.validate_method_validity(method)
		error_code = 2503
		!validate_method(method) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_web_link_validity(web_link)
		error_code = 2504
		(web_link.length > 0 && !validate_url(web_link)) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_google_play_link_validity(google_play_link)
		error_code = 2505
		(google_play_link.length > 0 && !validate_url(google_play_link)) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	def self.validate_microsoft_store_link_validity(microsoft_store_link)
		error_code = 2506
		(microsoft_store_link.length > 0 && !validate_url(microsoft_store_link)) ? get_validation_hash(false, error_code, 400) : get_validation_hash
	end

	# Methods for availability of fields
	def self.validate_email_availability(email)
		error_code = 2701
		User.exists?(email: email) ? get_validation_hash(false, error_code, 409) : get_validation_hash
	end

	def self.validate_table_object_uuid_availability(uuid)
		error_code = 2702
		TableObject.exists?(uuid: uuid) ? get_validation_hash(false, error_code, 409) : get_validation_hash
	end

	def self.validate_web_push_subscription_uuid_availability(uuid)
		error_code = 2702
		WebPushSubscription.exists?(uuid: uuid) ? get_validation_hash(false, error_code, 409) : get_validation_hash
	end

	def self.validate_notification_uuid_availability(uuid)
		error_code = 2702
		Notification.exists?(uuid: uuid) ? get_validation_hash(false, error_code, 409) : get_validation_hash
	end

	# Methods for existence of fields
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

	def self.validate_table_object_existence(table_object)
		error_code = 2805
		table_object.nil? ? get_validation_hash(false, error_code, 404) : get_validation_hash
	end

	def self.validate_session_existence(session)
		error_code = 2806
		session.nil? ? get_validation_hash(false, error_code, 404) : get_validation_hash
	end

	def self.validate_table_object_user_access_existence(access)
		error_code = 2807
		access.nil? ? get_validation_hash(false, error_code, 404) : get_validation_hash
	end

	def self.validate_notification_existence(notification)
		error_code = 2808
		notification.nil? ? get_validation_hash(false, error_code, 404) : get_validation_hash
	end

	def self.validate_api_existence(api)
		error_code = 2809
		api.nil? ? get_validation_hash(false, error_code, 404) : get_validation_hash
	end

	def self.validate_api_endpoint_existence(api_endpoint)
		error_code = 2810
		api_endpoint.nil? ? get_validation_hash(false, error_code, 404) : get_validation_hash
	end

	# Methods for non-existence of fields
	def self.validate_table_object_user_access_nonexistence(access)
		error_code = 2901
		!access.nil? ? get_validation_hash(false, error_code, 409) : get_validation_hash
	end

	# Utility methods
	def self.validate_email(email)
		/[a-z0-9!#$%&'*+=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/.match?(email)
	end

	def self.validate_name(name)
		/^([A-Z]|[a-z])+$/.match?(name)
	end

	def self.validate_method(method)
		["get", "post", "put", "delete"].include?(method.downcase)
	end

	def self.validate_url(url)
		/^(https?:\/\/)?[\w.-]+(\.[\w.-]+)+[\w\-._~\/?#@&\+,;=]+$/.match?(url)
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
		when 1106
			"The table object is not a file"
		when 1107
			"The table object has no file"
		when 1108
			"Not sufficient storage available"
		when 1109
			"User is already confirmed"
		when 1201
			"Password is incorrect"
		when 1202
			"Email confirmation token is incorrect"
		when 1203
			"Password confirmation token is incorrect"
		when 1301
			"JWT invalid"
		when 1302
			"JWT expired"
		when 1303
			"JWT unexpected error"
		when 1401
			"Missing header: Authorization"
		when 1402
			"Missing header: Content-Type"
		when 1501
			"User.old_email is empty"
		when 1502
			"User.new_email is empty"
		when 1503
			"User.new_password is empty"
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
		when 2109
			"Missing field: table_id"
		when 2110
			"Missing field: properties"
		when 2111
			"Missing field: endpoint"
		when 2112
			"Missing field: p256dh"
		when 2113
			"Missing field: auth"
		when 2114
			"Missing field: time"
		when 2115
			"Missing field: interval"
		when 2116
			"Missing field: title"
		when 2117
			"Missing field: body"
		when 2118
			"Missing field: path"
		when 2119
			"Missing field: method"
		when 2120
			"Missing field: commands"
		when 2121
			"Missing field: errors"
		when 2122
			"Missing field: env_vars"
		when 2123
			"Missing field: description"
		when 2124
			"Missing field: email_confirmation_token"
		when 2125
			"Missing field: password_confirmation_token"
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
		when 2210
			"Field has wrong type: uuid"
		when 2211
			"Field has wrong type: table_id"
		when 2212
			"Field has wrong type: file"
		when 2213
			"Field has wrong type: properties"
		when 2214
			"Field has wrong type: name (for TableObjectProperty)"
		when 2215
			"Field has wrong type: value (for TableObjectProperty)"
		when 2216
			"Field has wrong type: ext"
		when 2217
			"Field has wrong type: table_alias"
		when 2218
			"Field has wrong type: endpoint"
		when 2219
			"Field has wrong type: p256dh"
		when 2220
			"Field has wrong type: auth"
		when 2221
			"Field has wrong type: time"
		when 2222
			"Field has wrong type: interval"
		when 2223
			"Field has wrong type: title"
		when 2224
			"Field has wrong type: body"
		when 2225
			"Field has wrong type: path"
		when 2226
			"Field has wrong type: method"
		when 2227
			"Field has wrong type: commands"
		when 2228
			"Field has wrong type: caching"
		when 2229
			"Field has wrong type: params"
		when 2230
			"Field has wrong type: errors"
		when 2231
			"Field has wrong type: code"
		when 2232
			"Field has wrong type: message"
		when 2233
			"Field has wrong type: env_vars"
		when 2234
			"Field has wrong type: value (for ApiEnvVar)"
		when 2235
			"Field has wrong type: jwt"
		when 2236
			"Field has wrong type: description"
		when 2237
			"Field has wrong type: published"
		when 2238
			"Field has wrong type: web_link"
		when 2239
			"Field has wrong type: google_play_link"
		when 2240
			"Field has wrong type: microsoft_store_link"
		when 2241
			"Field has wrong type: email_confirmation_token"
		when 2242
			"Field has wrong type: password_confirmation_token"
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
		when 2307
			"Field too short: name (for TableObjectProperty)"
		when 2308
			"Field too short: value (for TableObjectProperty)"
		when 2309
			"Field too short: ext"
		when 2310
			"Field too short: endpoint"
		when 2311
			"Field too short: p256dh"
		when 2312
			"Field too short: auth"
		when 2313
			"Field too short: title"
		when 2314
			"Field too short: body"
		when 2315
			"Field too short: path"
		when 2316
			"Field too short: commands"
		when 2317
			"Field too short: params"
		when 2318
			"Field too short: message"
		when 2319
			"Field too short: value (for ApiEnvVar)"
		when 2320
			"Field too short: description"
		when 2321
			"Field too short: web_link"
		when 2322
			"Field too short: google_play_link"
		when 2323
			"Field too short: microsoft_store_link"
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
		when 2407
			"Field too long: name (for TableObjectProperty)"
		when 2408
			"Field too long: value (for TableObjectProperty)"
		when 2409
			"Field too long: ext"
		when 2410
			"Field too long: endpoint"
		when 2411
			"Field too long: p256dh"
		when 2412
			"Field too long: auth"
		when 2413
			"Field too long: title"
		when 2414
			"Field too long: body"
		when 2415
			"Field too long: path"
		when 2416
			"Field too long: commands"
		when 2417
			"Field too long: params"
		when 2418
			"Field too long: message"
		when 2419
			"Field too long: value (for ApiEnvVar)"
		when 2420
			"Field too long: description"
		when 2421
			"Field too long: web_link"
		when 2422
			"Field too long: google_play_link"
		when 2423
			"Field too long: microsoft_store_link"
		when 2501
			"Field invalid: email"
		when 2502
			"Field invalid: name"
		when 2503
			"Field invalid: method"
		when 2504
			"Field invalid: web_link"
		when 2505
			"Field invalid: google_play_link"
		when 2506
			"Field invalid: microsoft_store_link"
		when 2701
			"Field already taken: email"
		when 2702
			"Field already taken: uuid"
		when 2801
			"Resource does not exist: User"
		when 2802
			"Resource does not exist: Dev"
		when 2803
			"Resource does not exist: App"
		when 2804
			"Resource does not exist: Table"
		when 2805
			"Resource does not exist: TableObject"
		when 2806
			"Resource does not exist: Session"
		when 2807
			"Resource does not exist: TableObjectUserAccess"
		when 2808
			"Resource does not exist: Notification"
		when 2809
			"Resource does not exist: Api"
		when 2810
			"Resource does not exist: ApiEndpoint"
		when 2901
			"Resource already exists: TableObjectUserAccess"
		end
	end
end